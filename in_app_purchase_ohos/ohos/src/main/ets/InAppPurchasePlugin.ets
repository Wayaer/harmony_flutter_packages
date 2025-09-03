import { iap } from '@kit.IAPKit'
import { Any } from '@ohos/flutter_ohos';

import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  BinaryMessenger,
  MethodChannel,
} from '@ohos/flutter_ohos';
import { common } from '@kit.AbilityKit';
import { MethodCallHandlerImpl } from './MethodCallHandlerImpl';

const TAG = "InAppPurchasePlugin"

export class InAppPurchasePlugin implements FlutterPlugin, AbilityAware {
  private methodChannel: MethodChannel | null = null
  private methodCallHandler: MethodCallHandlerImpl | null = null
  private context: common.UIAbilityContext | null = null

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.setUpMethodChannel(binding.getBinaryMessenger(), binding.getApplicationContext());
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.teardownMethodChannel();
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context
    this.methodCallHandler?.setContext(this.context)
  }

  onDetachedFromAbility(): void {
    this.methodCallHandler?.setContext(null)
  }

  getUniqueClassName(): string {
    return TAG
  }

  setUpMethodChannel(messenger: BinaryMessenger, context: common.Context) {
    this.methodChannel = new MethodChannel(messenger, "plugins.flutter.io/in_app_purchase");
    this.methodCallHandler =
      new MethodCallHandlerImpl(context, this.methodChannel);
    this.methodChannel.setMethodCallHandler(this.methodCallHandler);
  }

  teardownMethodChannel() {
    this.methodChannel?.setMethodCallHandler(null);
    this.methodChannel = null;
    this.methodCallHandler = null;
    this.context = null;
  }
}

export class MethodNames {
  static QUERY_ENVIRONMENT_STATUS: string = "iap#queryEnvironmentStatus";
  static QUERY_PRODUCTS: string = "iap#queryProducts";
  static CREATE_PURCHASE: string = "iap#createPurchase";
  static START_OBSERVING_TRANSACTION_QUEUE: string = "iap#startObservingTransactionQueue";
  static STOP_OBSERVING_TRANSACTION_QUEUE: string = "iap#stopObservingTransactionQueue";
  static RETRIEVE_RECEIPT_DATA: string = "iap#retrieveReceiptData";
  static TRANSACTIONS: string = "iap#transactions";
  static FINISH_PURCHASE: string = "iap#finishPurchase";
  static RESTORE_TRANSACTIONS: string = "iap#restoreTransactions";
}


export const ProductType: Array<iap.ProductType> = [
  iap.ProductType.CONSUMABLE,
  iap.ProductType.NONCONSUMABLE,
  iap.ProductType.AUTORENEWABLE
]

export interface PurchaseData {
  type: number;
  jwsPurchaseOrder?: string;
  jwsSubscriptionStatus?: string;
}


export class PurchaseOrderPayload {
  applicationId: string = '';
  countryCode: string = '';
  environment: string = '';
  payOrderId: string = '';
  price: number = 0;
  productId: string = '';
  productType: number = 0;
  purchaseOrderId: string = '';
  purchaseTime: number = 0;
  purchaseToken: string = '';
  signedTime: number = 0;
}

export class PurchaseSubGroupStatusPayload {
  environment: string = '';
  applicationId: string = '';
  packageName: string = '';
  subGroupId: string = '';
  lastSubscriptionStatus?: PurchaseSubscriptionStatus;
  historySubscriptionStatusList?: Any[] = [];
}

export class PurchaseSubscriptionStatus {
  subGroupGenerationId: string = '';
  subscriptionId: string = '';
  purchaseToken: string = '';
  status: string = '';
  expiresTime: number = 0;
  lastPurchaseOrder?: Any = {};
  recentPurchaseOrderList?: Any[] = [];
  renewalInfo?: Any = {};
}

export enum TransactionState {
  purchasing = 0,
  purchased = 1,
  failed = 2,
  restored = 3,
  deferred = 4,
  unspecified = -1,
}
