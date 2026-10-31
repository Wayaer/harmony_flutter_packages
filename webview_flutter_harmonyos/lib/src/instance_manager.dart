// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

@immutable
mixin Copyable {
  @protected
  Copyable copy();
}

class InstanceManager {
  InstanceManager({required void Function(int) onWeakReferenceRemoved}) {
    this.onWeakReferenceRemoved = (int identifier) {
      _weakInstances.remove(identifier);
      onWeakReferenceRemoved(identifier);
    };
    _finalizer = Finalizer<int>(this.onWeakReferenceRemoved);
  }

  // 标识符限定在 [0, 2^16) 内，避免与宿主平台同时创建的对象（>= 2^16）冲突
  static const int _maxDartCreatedIdentifier = 65536;

  // 用 Expando 避免强引用实例，同时避免用 == 查找导致与副本比较时死循环
  final Expando<int> _identifiers = Expando<int>();
  final Map<int, WeakReference<Copyable>> _weakInstances = <int, WeakReference<Copyable>>{};
  final Map<int, Copyable> _strongInstances = <int, Copyable>{};
  late final Finalizer<int> _finalizer;
  int _nextIdentifier = 0;

  late final void Function(int) onWeakReferenceRemoved;

  int addDartCreatedInstance(Copyable instance) {
    final int identifier = _nextUniqueIdentifier();
    _addInstanceWithIdentifier(instance, identifier);
    return identifier;
  }

  int? removeWeakReference(Copyable instance) {
    final int? identifier = getIdentifier(instance);
    if (identifier == null) {
      return null;
    }

    _identifiers[instance] = null;
    _finalizer.detach(instance);
    onWeakReferenceRemoved(identifier);

    return identifier;
  }

  T? remove<T extends Copyable>(int identifier) {
    return _strongInstances.remove(identifier) as T?;
  }

  T? getInstanceWithWeakReference<T extends Copyable>(int identifier) {
    final Copyable? weakInstance = _weakInstances[identifier]?.target;

    if (weakInstance == null) {
      final Copyable? strongInstance = _strongInstances[identifier];
      if (strongInstance != null) {
        final Copyable copy = strongInstance.copy();
        _identifiers[copy] = identifier;
        _weakInstances[identifier] = WeakReference<Copyable>(copy);
        _finalizer.attach(copy, identifier, detach: copy);
        return copy as T;
      }
      return strongInstance as T?;
    }

    return weakInstance as T;
  }

  int? getIdentifier(Copyable instance) {
    return _identifiers[instance];
  }

  void addHostCreatedInstance(Copyable instance, int identifier) {
    _addInstanceWithIdentifier(instance, identifier);
  }

  void _addInstanceWithIdentifier(Copyable instance, int identifier) {
    assert(!containsIdentifier(identifier));
    assert(getIdentifier(instance) == null);
    assert(identifier >= 0);

    _identifiers[instance] = identifier;
    _weakInstances[identifier] = WeakReference<Copyable>(instance);
    _finalizer.attach(instance, identifier, detach: instance);

    final Copyable copy = instance.copy();
    _identifiers[copy] = identifier;
    _strongInstances[identifier] = copy;
  }

  bool containsIdentifier(int identifier) {
    return _weakInstances.containsKey(identifier) || _strongInstances.containsKey(identifier);
  }

  int _nextUniqueIdentifier() {
    late int identifier;
    do {
      identifier = _nextIdentifier;
      _nextIdentifier = (_nextIdentifier + 1) % _maxDartCreatedIdentifier;
    } while (containsIdentifier(identifier));
    return identifier;
  }
}
