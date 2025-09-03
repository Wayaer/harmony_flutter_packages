import { MethodCall, MethodCallHandler, MethodChannel, MethodResult, Log, Any } from '@ohos/flutter_ohos';
import { iap } from '@kit.IAPKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { JWTUtil } from './common/JWTUtil';
import { HashMap } from '@kit.ArkTS';
import { ObjToMap } from './common/TsUtil';
import {
  MethodNames,
  ProductType,
  PurchaseData,
  PurchaseOrderPayload,
  PurchaseSubGroupStatusPayload,
  TransactionState
} from './InAppPurchasePlugin';

const TAG = "MethodCallHandlerImpl"

export class IKError {
  code: number = 0
  domain: string = ''
  userInfo: Map<String, Any> = new Map()
}

export class MethodCallHandlerImpl implements MethodCallHandler {
  private context: common.UIAbilityContext | null = null
  private methodChannel: MethodChannel
  private observer: MethodChannel | null = null
  private productDetailsMap: HashMap<string, iap.Product> = new HashMap()

  constructor(context: common.Context, methodChannel: MethodChannel) {
    this.methodChannel = methodChannel
  }

  setContext(context: common.UIAbilityContext | null) {
    this.context = context
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case MethodNames.START_OBSERVING_TRANSACTION_QUEUE:
        this.startObserver()
        break;
      case MethodNames.STOP_OBSERVING_TRANSACTION_QUEUE:
        this.stopObserver()
        break;
      case MethodNames.QUERY_ENVIRONMENT_STATUS:
        this.isFeatureSupported(result)
        break;
      case MethodNames.QUERY_PRODUCTS:
        let productList: Array<string> = call.args as Array<string> ?? []
        this.queryProductDetails(productList, result)
        break;
      case MethodNames.CREATE_PURCHASE:
        this.purchaseGoods(call.args, result)
        break;
      case MethodNames.RETRIEVE_RECEIPT_DATA:
        result.success(null)
        break;
      case MethodNames.FINISH_PURCHASE:
        this.iapFinishPurchase(call, result)
        break;
      default:
        result.notImplemented();
    }
  }

  isFeatureSupported(result: MethodResult): void {
    try {
      iap.queryEnvironmentStatus(this.context).then(() => {
        result.success(true);
      }).catch((err: BusinessError) => {
        Log.e(TAG, `Failed to query environment status. Code is ${err.code}, message is ${err.message}`);
        result.success(false);
      })
    } catch (e) {
      Log.e(TAG, `Failed to query environment status. err: ${JSON.stringify(e)}`);
      result.success(false);
    }
  }

  queryProductDetails(list: Array<string>, result: MethodResult) {
    let productList: Array<Map<string, Object>> = []
    let count: number = 0
    let validProductsList: Array<string> = []
    let invalidProductIdentifiers: Array<string> = []
    ProductType.forEach((type) => {
      const queryProductParam: iap.QueryProductsParameter = {
        productType: type,
        productIds: list
      };
      iap.queryProducts(this.context, queryProductParam).then((result) => {
        let resultTemp = result.map((value) => {
          validProductsList.push(value.id)
          this.productDetailsMap.set(value.id, value)
          return ObjToMap(value)
        })
        productList.push(...resultTemp)
      }).catch((err: BusinessError) => {
        Log.e(TAG, `Failed to query products. Code is ${err.code}, message is ${err.message}`);
      }).finally(() => {
        count++
        if (count === ProductType.length) {
          let productDetailsResponse: HashMap<String, Object> = new HashMap()
          productDetailsResponse.set('products', productList)
          list.forEach((id) => {
            if (!validProductsList.includes(id)) {
              invalidProductIdentifiers.push(id)
            }
          })
          productDetailsResponse.set('invalidProductIdentifiers', invalidProductIdentifiers)
          result.success(productDetailsResponse)
        }
      })
    })
  }

  purchaseGoods(args: Any, result: MethodResult) {
    let map: Map<string, Object> = args as Map<string, Object>
    let id: string = map.get('productId') as string
    // 拉起支付接口前更新状态为支付中
    let mapRes: Map<string, Any> = new Map()
    mapRes.set('payment', args)
    mapRes.set('transactionState', TransactionState.purchasing)
    this.observer?.invokeMethod('updatedTransactions', [mapRes])
    this.createPurchase(id, map, result)
  }

  createPurchase(id: string, args: Map<string, Object>, result: MethodResult) {
    try {
      const type = this.productDetailsMap.get(id).type
      let createPurchaseParam: iap.PurchaseParameter = {
        productId: id,
        productType: type,
      }
      iap.createPurchase(this.context, createPurchaseParam).then(async (createPurchaseResult) => {
        let type: number = JSON.parse(createPurchaseResult.purchaseData).type
        if (type == iap.ProductType.AUTORENEWABLE) {
          let jwsSubscriptionStatus: string = JSON.parse(createPurchaseResult.purchaseData).jwsSubscriptionStatus;
          let purchaseStr = JWTUtil.decodeJwtObj(jwsSubscriptionStatus);
          let purchaseOrderPayload = JSON.parse(purchaseStr) as PurchaseSubGroupStatusPayload;
          let map: Map<string, Any> = new Map();
          map.set('payment', args)
          map.set('transactionIdentifier',
            purchaseOrderPayload.lastSubscriptionStatus?.lastPurchaseOrder.purchaseOrderId)
          map.set('transactionState', TransactionState.purchased)
          this.observer?.invokeMethod('updatedTransactions', [map])
        } else if (type == iap.ProductType.CONSUMABLE || type == iap.ProductType.NONCONSUMABLE) {
          let jwsPurchaseOrder: string = JSON.parse(createPurchaseResult.purchaseData).jwsPurchaseOrder;
          let purchaseStr = JWTUtil.decodeJwtObj(jwsPurchaseOrder);
          let purchaseOrderPayload = JSON.parse(purchaseStr) as PurchaseOrderPayload;
          let map: Map<string, Any> = new Map();
          map.set('payment', args)
          map.set('transactionIdentifier', purchaseOrderPayload.purchaseOrderId)
          map.set('transactionState', TransactionState.purchased)
          this.observer?.invokeMethod('updatedTransactions', [map])
        }
        result.success(null)
      }).catch((err: BusinessError) => {
        Log.e(TAG, `Failed to create purchase1. Code is ${err.code}, message is ${err.message}`);
        this.errorPurchase(args, err);
      })
    } catch (err) {
      const e: BusinessError = err as BusinessError;
      const msg: string = `Failed to create purchase. Code is ${e.code}, message is ${e.message}`;
      Log.e(TAG, msg);
      this.errorPurchase(args, err);
    }
  }

  errorPurchase(args: Map<string, Object>, err: BusinessError) {
    let map: Map<string, Any> = new Map();
    let iKError: IKError = new IKError()
    if (err) {
      iKError.code = err.code
      iKError.domain = err.message
    }
    map.set('error', iKError)
    map.set('payment', args)
    map.set('transactionState', TransactionState.failed)
    this.observer?.invokeMethod('updatedTransactions', [map])
  }

  finishPurchase(productType: iap.ProductType, purchaseToken: string, purchaseOrderId: string, result?: MethodResult) {
    let finishPurchaseParam: iap.FinishPurchaseParameter = {
      productType: productType,
      purchaseToken: purchaseToken,
      purchaseOrderId: purchaseOrderId
    };
    iap.finishPurchase(this.context, finishPurchaseParam).then(() => {
      Log.i(TAG, 'Succeeded in finishing purchase.');
      result?.success(true);
    }).catch((err: BusinessError) => {
      Log.e(TAG, `Failed to finish purchase. Code is ${err.code}, message is ${err.message}`);
      result?.error('' + err.code, err.message, err);
    });
  }

  queryPurchasesAsync(productType: iap.ProductType, result: MethodResult) {
    let param: iap.QueryPurchasesParameter = {
      productType: productType,
      queryType: iap.PurchaseQueryType.UNFINISHED
    };
    iap.queryPurchases(this.context, param).then((res: iap.QueryPurchaseResult) => {
      let purchaseDataList: string[] = res.purchaseDataList;
      if (purchaseDataList === undefined || purchaseDataList.length <= 0) {
        /* 购买成功后， 查询不到购买订单 返回失败. */
        Log.i(TAG, 'queryPurchases, purchaseDataList empty');
        result.error('UNAVAILABLE', 'purchaseDataList empty!', null);
        return;
      }
      this.purchaseCompletionByTypeProcessing(purchaseDataList, result)
    }).catch((err: BusinessError) => {
      Log.e(TAG, `Failed to query purchases. Code is ${err.code}, message is ${err.message}`);
      result.error('' + err.code, err.message, err);
    });
  }

  purchaseCompletionByTypeProcessing(purchaseDataList: string[], result: MethodResult) {
    for (let i = 0; i < purchaseDataList.length; i++) {
      let purchaseData = purchaseDataList[i];
      let type: number = JSON.parse(purchaseData).type
      let purchaseToken = ''
      let purchaseOrderId = ''
      //自动订阅类型
      if (type == iap.ProductType.AUTORENEWABLE) {
        let jwsSubscriptionStatus = (JSON.parse(purchaseData) as PurchaseData).jwsSubscriptionStatus;
        if (!jwsSubscriptionStatus) {
          Log.e(TAG, 'queryPurchases, jwsSubscriptionStatus invalid');
          continue;
        }
        let purchaseStr = JWTUtil.decodeJwtObj(jwsSubscriptionStatus);
        let purchaseOrderPayload = JSON.parse(purchaseStr) as PurchaseSubGroupStatusPayload;
        if (purchaseOrderPayload.lastSubscriptionStatus) {
          purchaseToken = purchaseOrderPayload.lastSubscriptionStatus.purchaseToken
          purchaseOrderId = purchaseOrderPayload.lastSubscriptionStatus.lastPurchaseOrder.purchaseOrderId
        }
      } else {
        //非自动订阅类型
        let jwsPurchaseOrder = (JSON.parse(purchaseData) as PurchaseData).jwsPurchaseOrder;
        if (!jwsPurchaseOrder) {
          Log.e(TAG, 'queryPurchases, jwsPurchaseOrder invalid');
          continue;
        }
        let purchaseStr = JWTUtil.decodeJwtObj(jwsPurchaseOrder);
        let purchaseOrderPayload = JSON.parse(purchaseStr) as PurchaseOrderPayload;
        purchaseToken = purchaseOrderPayload.purchaseToken
        purchaseOrderId = purchaseOrderPayload.purchaseOrderId
      }
      this.finishPurchase(type, purchaseToken, purchaseOrderId, result);
    }
  }

  iapFinishPurchase(call: MethodCall, result: MethodResult) {
    let finishPurchaseMap: Map<string, Object> = call.args as Map<string, Object>
    let productIdentifier: string = finishPurchaseMap.get('productIdentifier') as string
    let product: iap.Product = this.productDetailsMap.get(productIdentifier)
    // let productType: string = finishPurchaseMap.get('productType') as string
    let productType: iap.ProductType = product.type
    if (!product) {
      Log.i(TAG, `Failed to get productType.`);
      result.error('UNAVAILABLE', 'productType is null!', null);
      return;
    } else {
      this.queryPurchasesAsync(productType, result);
    }
  }

  startObserver() {
    this.observer = this.methodChannel
  }

  stopObserver() {
    this.observer = null
  }
}