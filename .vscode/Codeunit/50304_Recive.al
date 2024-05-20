codeunit 50304 ReceiveChanges
{
    trigger OnRun()
    begin

    end;

    // //Azhar++
    // //Disply Recipt Header +++
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrders_OnAfterSetFromWarehouseReceiptHeader', '', false, false)]
    // local procedure ShowingAssignedUserId(var _BaseOrderElement: Record "MOB NS BaseDataModel Element"; _WhseReceiptHeader: Record "Warehouse Receipt Header")
    // begin
    //     _BaseOrderElement.Set_DisplayLine5(_WhseReceiptHeader."Assigned User ID");
    // end;

    //Disply Recipt Header +++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrders_OnAfterSetFromAnyHeader', '', false, false)]
    local procedure OnGetReceiveOrders_OnAfterSetFromAnyHeader(_RecRef: RecordRef; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        L_WarehouseReciptHeader: Record "Warehouse Receipt Header";
        L_PurchaseHeader: Record "Purchase Header";
        L_TransferHeader: Record "Transfer Header";
    begin
        case _RecRef.Number of
            database::"Warehouse Receipt Header":
                begin
                    L_WarehouseReciptHeader.Reset();
                    _RecRef.SetTable(L_WarehouseReciptHeader);
                    _BaseOrderElement.Set_DisplayLine5(L_WarehouseReciptHeader."Assigned User ID");
                end;
            Database::"Purchase Header":
                begin
                    L_PurchaseHeader.Reset();
                    _RecRef.SetTable(L_PurchaseHeader);
                    _BaseOrderElement.Set_DisplayLine5(L_PurchaseHeader."Assigned User ID");
                end;
            Database::"Transfer Header":
                begin
                    L_TransferHeader.Reset();
                    _RecRef.SetTable(L_TransferHeader);
                    _BaseOrderElement.Set_DisplayLine5(L_TransferHeader."Assigned User ID");
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrderLines_OnAfterSetFromAnyLine', '', false, false)]
    local procedure OnGetReceiveOrderLines_OnAfterSetFromAnyLine(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        L_WarehouseRecptLine: Record "Warehouse Receipt Line";
        L_PurchaseLine: Record "Purchase Line";
        L_TransferLine: Record "Transfer Line";
        L_Item: Record Item;
        mobtool: Codeunit "MOB Toolbox";
    begin
        case _RecRef.Number of
            database::"Warehouse Receipt Line":
                begin
                    L_WarehouseRecptLine.Reset();
                    _RecRef.SetTable(L_WarehouseRecptLine);

                    L_Item.Reset();
                    if L_Item.Get(L_WarehouseRecptLine."Item No.") then begin
                        _BaseOrderLineElement.Set_DisplayLine4(StrSubstNo('WH Class Code : %1', L_Item."Warehouse Class Code") + mobtool.CRLFSeparator() + StrSubstNo('Variant Code : %1', L_WarehouseRecptLine."Variant Code"));
                    end;

                end;
            Database::"Purchase Line":
                begin
                    L_PurchaseLine.Reset();
                    _RecRef.SetTable(L_PurchaseLine);

                    L_Item.Reset();
                    if L_Item.Get(L_PurchaseLine."No.") then begin
                        _BaseOrderLineElement.Set_DisplayLine4(StrSubstNo('WH Class Code : %1', L_Item."Warehouse Class Code") + mobtool.CRLFSeparator() + StrSubstNo('Variant Code : %1', L_PurchaseLine."Variant Code"));
                    end;
                end;
            Database::"Transfer Line":
                begin
                    L_TransferLine.Reset();
                    _RecRef.SetTable(L_TransferLine);

                    L_Item.Reset();
                    if L_Item.Get(L_TransferLine."Item No.") then begin
                        _BaseOrderLineElement.Set_DisplayLine4(StrSubstNo('WH Class Code : %1', L_Item."Warehouse Class Code") + mobtool.CRLFSeparator() + StrSubstNo('Variant Code : %1', L_TransferLine."Variant Code"));
                    end;
                end;
        end;
    end;

    //Add Header Step on warehouse Receive order
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrderLines_OnAddStepsToAnyHeader', '', true, true)]
    procedure OnGetReceiveOrderLines_OnAddStepsToAnyHeader(_RecRef: RecordRef; var _StepsElement: Record "MOB Steps Element")
    begin
        with _StepsElement do begin
            if (_RecRef.Number() in [DataBase::"Warehouse Receipt Header", Database::"Purchase Header", Database::"Transfer Header"]) then begin
                Create_RadioButtonStep(50000, 'CurtainSideVehicle', 'Curtain Side Vehicle', '', '', '', 'True;False');
                Create_RadioButtonStep(50001, 'DataLoggerReceived', 'Data Logger Received', '', '', '', 'True;False');
            end;
        end;
    end;


    //Update CurtainSideVehicle and DataLoggerReceived  on receipt header+++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnPostReceiveOrder_OnBeforePostWarehouseReceipt', '', true, true)]
    procedure OnPostReceiveOrder_OnBeforePostWarehouseReceipt(var _OrderValues: Record "MOB Common Element"; var _WhseReceiptHeader: Record "Warehouse Receipt Header")
    var
        L_PurchaseHeader: Record "Purchase Header";
        L_WarehouseReciptLine: Record "Warehouse Receipt Line";
    begin
        IF _OrderValues.GetValue('CurtainSideVehicle', true) <> '' THEN
            Evaluate(_WhseReceiptHeader."Curtain Side Vehicle", _OrderValues.GetValue('CurtainSideVehicle', true));

        IF _OrderValues.GetValue('DataLoggerReceived', true) <> '' THEN
            Evaluate(_WhseReceiptHeader."Data Logger Received", _OrderValues.GetValue('DataLoggerReceived', true));

        //Update Purchase Header for Data flow in Posted documents++
        L_WarehouseReciptLine.Reset();
        L_WarehouseReciptLine.SetRange("No.", _WhseReceiptHeader."No.");
        if L_WarehouseReciptLine.FindSet() then begin
            repeat
                L_PurchaseHeader.Reset();
                L_PurchaseHeader.SetRange("Document Type", L_PurchaseHeader."Document Type"::Order);
                L_PurchaseHeader.SetRange("No.", L_WarehouseReciptLine."Source No.");
                if L_PurchaseHeader.FindFirst() then begin
                    Evaluate(L_PurchaseHeader."Curtain Side Vehicle", _OrderValues.GetValue('CurtainSideVehicle', true));
                    Evaluate(L_PurchaseHeader."Data Logger Received", _OrderValues.GetValue('DataLoggerReceived', true));
                    L_PurchaseHeader.Modify();
                end;
            until L_WarehouseReciptLine.Next() = 0;
        end;
    end;

    //Update CurtainSideVehicle and DataLoggerReceived  on Purchase header+++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnPostReceiveOrder_OnBeforePostPurchaseOrder', '', true, true)]
    procedure OnPostReceiveOrder_OnBeforePostPurchaseOrder(var _OrderValues: Record "MOB Common Element"; var _PurchHeader: Record "Purchase Header")
    begin
        IF _OrderValues.GetValue('CurtainSideVehicle', true) <> '' THEN
            Evaluate(_PurchHeader."Curtain Side Vehicle", _OrderValues.GetValue('CurtainSideVehicle', true));

        IF _OrderValues.GetValue('DataLoggerReceived', true) <> '' THEN
            Evaluate(_PurchHeader."Data Logger Received", _OrderValues.GetValue('DataLoggerReceived', true));

    end;

    //Update CurtainSideVehicle and DataLoggerReceived  on Transfer header+++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnPostReceiveOrder_OnBeforePostTransferOrder', '', true, true)]
    procedure OnPostReceiveOrder_OnBeforePostTransferOrder(var _OrderValues: Record "MOB Common Element"; var _TransferHeader: Record "Transfer Header")
    begin
        IF _OrderValues.GetValue('CurtainSideVehicle', true) <> '' THEN
            Evaluate(_TransferHeader."Curtain Side Vehicle", _OrderValues.GetValue('CurtainSideVehicle', true));

        IF _OrderValues.GetValue('DataLoggerReceived', true) <> '' THEN
            Evaluate(_TransferHeader."Data Logger Received", _OrderValues.GetValue('DataLoggerReceived', true));

    end;

    // //Update NoofPallet on receipt header+++
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnPostReceiveOrder_OnBeforePostAnyOrder', '', true, true)]
    // procedure OnPostReceiveOrder_OnBeforePostAnyOrder(var _OrderValues: Record "MOB Common Element"; var _RecRef: RecordRef)
    // var
    //     L_WareRecptHeader: Record "Warehouse Receipt Header";
    //     L_PurchaseHeader: Record "Purchase Header";
    //     L_WarehouseReciptLine: Record "Warehouse Receipt Line";
    //     L_TransferHeader: Record "Transfer Header";
    //     _PurchaseHeader: Record "Purchase Header";
    // begin
    //     case _RecRef.Number of
    //         database::"Warehouse Receipt Header":
    //             begin
    //                 L_WareRecptHeader.Reset();
    //                 _RecRef.SetTable(L_WareRecptHeader);

    //                 IF _OrderValues.GetValue('CurtainSideVehicle', true) <> '' THEN
    //                     Evaluate(L_WareRecptHeader."Curtain Side Vehicle", _OrderValues.GetValue('CurtainSideVehicle', true));

    //                 IF _OrderValues.GetValue('DataLoggerReceived', true) <> '' THEN
    //                     Evaluate(L_WareRecptHeader."Data Logger Received", _OrderValues.GetValue('DataLoggerReceived', true));

    //                 //Update Purchase Header for Data flow in Posted documents++
    //                 L_WarehouseReciptLine.Reset();
    //                 L_WarehouseReciptLine.SetRange("No.", L_WareRecptHeader."No.");
    //                 if L_WarehouseReciptLine.FindSet() then begin
    //                     repeat
    //                         L_PurchaseHeader.Reset();
    //                         L_PurchaseHeader.SetRange("Document Type", L_PurchaseHeader."Document Type"::Order);
    //                         L_PurchaseHeader.SetRange("No.", L_WarehouseReciptLine."Source No.");
    //                         if L_PurchaseHeader.FindFirst() then begin
    //                             Evaluate(L_PurchaseHeader."Curtain Side Vehicle", _OrderValues.GetValue('CurtainSideVehicle', true));
    //                             Evaluate(L_PurchaseHeader."Data Logger Received", _OrderValues.GetValue('DataLoggerReceived', true));
    //                             L_PurchaseHeader.Modify();
    //                         end;
    //                     until L_WarehouseReciptLine.Next() = 0;
    //                 end;
    //             end;
    //         Database::"Purchase Header":
    //             begin
    //                 _PurchaseHeader.Reset();
    //                 _RecRef.SetTable(_PurchaseHeader);

    //                 IF _OrderValues.GetValue('CurtainSideVehicle', true) <> '' THEN
    //                     Evaluate(_PurchaseHeader."Curtain Side Vehicle", _OrderValues.GetValue('CurtainSideVehicle', true));


    //                 IF _OrderValues.GetValue('DataLoggerReceived', true) <> '' THEN
    //                     Evaluate(_PurchaseHeader."Data Logger Received", _OrderValues.GetValue('DataLoggerReceived', true));
    //                 _PurchaseHeader.Modify();
    //             end;
    //         Database::"Transfer Header":
    //             begin
    //                 L_TransferHeader.Reset();
    //                 _RecRef.SetTable(L_TransferHeader);

    //                 IF _OrderValues.GetValue('CurtainSideVehicle', true) <> '' THEN
    //                     Evaluate(L_TransferHeader."Curtain Side Vehicle", _OrderValues.GetValue('CurtainSideVehicle', true));

    //                 IF _OrderValues.GetValue('DataLoggerReceived', true) <> '' THEN
    //                     Evaluate(L_TransferHeader."Data Logger Received", _OrderValues.GetValue('DataLoggerReceived', true));
    //                 L_TransferHeader.Modify();
    //             end;
    //     end;
    // end;


    //Update Message for after Posting++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnPostReceiveOrder_OnAfterPostAnyOrder', '', false, false)]
    local procedure OnPostReceiveOrder_OnAfterPostAnyOrder(var _RecRef: RecordRef; var _ResultMessage: Text)
    var
        L_WarehouseReciptHeader: Record "Warehouse Receipt Header";
        L_WarehouseReceiptLine: Record "Warehouse Receipt Line";
        L_PurchaseHeader: Record "Purchase Header";
        L_TransferHeader: Record "Transfer Header";
        MOBToolbox: Codeunit "MOB Toolbox";
    begin
        case _RecRef.Number of
            database::"Warehouse Receipt Line":
                begin
                    L_WarehouseReceiptLine.Reset();
                    _RecRef.SetTable(L_WarehouseReceiptLine);

                    L_WarehouseReciptHeader.Reset();
                    L_WarehouseReciptHeader.SetRange("No.", L_WarehouseReceiptLine."No.");
                    if L_WarehouseReciptHeader.FindFirst() then begin
                        if L_WarehouseReciptHeader."Data Logger Received" = true then begin
                            _ResultMessage += MOBToolbox.CRLFSeparator() + MOBToolbox.CRLFSeparator() + 'Delivery to be placed in Quarantine';
                        end;
                    end;
                end;
            Database::"Purchase Header":
                begin
                    L_PurchaseHeader.Reset();
                    _RecRef.SetTable(L_PurchaseHeader);

                    if L_PurchaseHeader."Data Logger Received" = true then begin
                        _ResultMessage += MOBToolbox.CRLFSeparator() + MOBToolbox.CRLFSeparator() + 'Delivery to be placed in Quarantine';
                    end;

                end;
            Database::"Transfer Header":
                begin
                    L_TransferHeader.Reset();
                    _RecRef.SetTable(L_TransferHeader);

                    if L_TransferHeader."Data Logger Received" = true then begin
                        _ResultMessage += MOBToolbox.CRLFSeparator() + MOBToolbox.CRLFSeparator() + 'Delivery to be placed in Quarantine';
                    end;
                end;
        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure GetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    var
        Options: List of [Text];
    begin
        _HeaderFields.InitConfigurationKey('ReceiveOrderFilters');
        _HeaderFields.Create_ListFieldFromListValues(21, 'TypeFilter', 'Source Type:', 'Purchase Order;Transfer Order;ALL', 'Purchase Order');
        _HeaderFields.Set_optional(true);
        _HeaderFields.Save();

        // _HeaderFields.Create_IntegerField(16, 'SourceNo', 'Source No');
        // _HeaderFields.Set_optional(true);
        // _HeaderFields.Save();

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAfterAddHeaderField', '', false, false)]
    local procedure OnGetReferenceData_OnAfterAddHeaderField(var _HeaderField: Record "MOB HeaderField Element")
    begin
        if _HeaderField.name = 'PurchaseOrderNumber' then begin
            _HeaderField.Set_label('Source No.:');
            _HeaderField.Modify();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrders_OnSetFilterWarehouseReceipt', '', false, false)]
    local procedure OnGetReceiveOrders_OnSetFilterWarehouseReceipt(_HeaderFilter: Record "MOB NS Request Element"; var _WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        case _HeaderFilter."Name" of
            'TypeFilter':
                begin
                    if _HeaderFilter."Value" <> 'All' then begin
                        if _HeaderFilter.Value = 'Purchase Order' then
                            _WhseReceiptHeader.SetRange(_SourceDocument, _WhseReceiptHeader._SourceDocument::"Purchase Order");


                        if _HeaderFilter.Value = 'Transfer Order' then
                            _WhseReceiptHeader.SetRange(_SourceDocument, _WhseReceiptHeader._SourceDocument::"Inbound Transfer");

                    end;

                end;
        // 'SourceNo':
        //     begin
        //         // if _HeaderFilter.Value <> '' then begin
        //         //     L_warehouseLine.Reset();
        //         //     L_warehouseLine.SetRange("Source No.", _HeaderFilter.Value);
        //         //     L_warehouseLine.SetRange("Activity Type", L_warehouseLine."Activity Type"::"Put-away");
        //         //     if L_warehouseLine.FindFirst() then begin
        //         //         _WhseActivityHeader.SetRange("No.", L_warehouseLine."No.");
        //         //     end else
        //         //         Error('Order does not exist');
        //         // end;
        //     end;

        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrders_OnSetFilterTransferOrder', '', false, false)]
    local procedure OnGetReceiveOrders_OnSetFilterTransferOrder(_HeaderFilter: Record "MOB NS Request Element"; var _TransferHeader: Record "Transfer Header")
    begin
        //have created one field named as ("Clear Filter") on transfer Header to manage filters in tasklet++
        //This is field is blank all times++
        case _HeaderFilter."Name" of
            'TypeFilter':
                begin
                    if _HeaderFilter."Value" <> 'All' then begin
                        if _HeaderFilter.Value = 'Purchase Order' then
                            _TransferHeader.SetFilter("Clear Filter", '<>%1', '');

                        //if _HeaderFilter.Value = 'Transfer Order' then;
                    end;

                end;
        // 'SourceNo':
        //     begin
        //         // if _HeaderFilter.Value <> '' then begin
        //         //     L_warehouseLine.Reset();
        //         //     L_warehouseLine.SetRange("Source No.", _HeaderFilter.Value);
        //         //     L_warehouseLine.SetRange("Activity Type", L_warehouseLine."Activity Type"::"Put-away");
        //         //     if L_warehouseLine.FindFirst() then begin
        //         //         _WhseActivityHeader.SetRange("No.", L_warehouseLine."No.");
        //         //     end else
        //         //         Error('Order does not exist');
        //         // end;
        //     end;

        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrders_OnSetFilterPurchaseOrder', '', false, false)]
    local procedure OnGetReceiveOrders_OnSetFilterPurchaseOrder(_HeaderFilter: Record "MOB NS Request Element"; var _PurchHeader: Record "Purchase Header")
    begin
        case _HeaderFilter."Name" of
            'TypeFilter':
                begin
                    if _HeaderFilter."Value" <> 'All' then begin
                        if _HeaderFilter.Value = 'Purchase Order' then
                            _PurchHeader.SetRange("Document Type", _PurchHeader."Document Type"::Order);


                        if _HeaderFilter.Value = 'Transfer Order' then
                            _PurchHeader.SetRange("Clear Filter", '<>%1', '');

                    end;
                end;
        // 'SourceNo':
        //     begin
        //         // if _HeaderFilter.Value <> '' then begin
        //         //     L_warehouseLine.Reset();
        //         //     L_warehouseLine.SetRange("Source No.", _HeaderFilter.Value);
        //         //     L_warehouseLine.SetRange("Activity Type", L_warehouseLine."Activity Type"::"Put-away");
        //         //     if L_warehouseLine.FindFirst() then begin
        //         //         _WhseActivityHeader.SetRange("No.", L_warehouseLine."No.");
        //         //     end else
        //         //         Error('Order does not exist');
        //         // end;
        //     end;

        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrderLines_OnAfterSetFromWarehouseReceiptLine', '', false, false)]
    local procedure OnGetReceiveOrderLines_OnAfterSetFromWarehouseReceiptLine(_WhseReceiptLine: Record "Warehouse Receipt Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
        _BaseOrderLineElement.Set_RegisteredQuantity('0');
        _BaseOrderLineElement.Modify();
        //_BaseOrderLineElement.Set_Quantity(0);
        //_BaseOrderLineElement.Set_BarcodeQuantity('0');
        //_BaseOrderLineElement.Set_RegisterQuantityByScan(true);
        //_BaseOrderLineElement.Set_BarcodeQuantity('');
        //_Steps.Create_QuantityByScanStep();
        //_BaseOrderLineElement.Set_Quantity(0);
        //_Steps.Create_DecimalStep_QuantityPerLabel(0);
        //_Steps.q
        //_Steps
        //_BaseOrderLineElement.Set_Quantity(0);
        //_BaseOrderLineElement.Get_RegisterQuantityByScan();
        //_BaseOrderLineElement.Set_RegisterQuantityByScan('0');
        //_BaseOrderLineElement.Set_RegisteredQuantity(0);
        //_BaseOrderLineElement.Set_RegisterQuantityByScan(true);
        //_BaseOrderLineElement.Modify();

    end;
    //Azhar--
    var
        myInt: Integer;
}