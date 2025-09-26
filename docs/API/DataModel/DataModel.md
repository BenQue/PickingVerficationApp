# prodcutionOrderTable 生产订单订单头表

    orderNumber string //生产订单号码（唯一）
    productNumber string //产品物料号码
    productDesc string //产品描述
    finalOrdNumber  string  //最终成品生产订单号码
    finalProduct string //最终成品物料号码
    finalPONumber string //最终成品订货号
    finalProDesc string //最终成品描述
    assemblyLine string //装配生产线
    status string //订单状态
    materialsCount int //拣配物料总计数
    cuttingCount int //断线物料计数
    centerWHCount int //中央仓物料计数
    autoWHCount int //自动仓物料计数
    labelCount int //标签计数
    remark string //订单备注
    priority string //订单优先级

# productionBOMTable 生产订单物料明细表

    orderNumber string  //生产订单号码
    rawMaterial string  //原材料物料号码
    rawMatDesc  string  //原材料物料描述
    category    string  //物料分类（断线物料，中央仓物料，自动化库物料，标签物料）
    quantity    string  //物料数量
    pickQty string  //拣配完成数量
    pickStatus   string  //拣配状态
    remark  string  //物料备注
