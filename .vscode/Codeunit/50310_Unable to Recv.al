codeunit 50310 "Unable To Receive"
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure MynGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        _HeaderFields.InitConfigurationKey('UnableToReceive'); // Name of Header

        // Add Header fields
        // Using pre-defined helper-functions makes it easy to transfer values as field names match 100%
        _HeaderFields.Create_TextField_OrderBackendID(10);
        _HeaderFields.Set_locked(true);

        _HeaderFields.Create_ListField_Location(11);    // 'Location' is a known field on OrderLines response
        _HeaderFields.Set_locked(true);

        _HeaderFields.Create_TextField_ItemNumber(30);  // 'ItemNumber' is a known field on OrderLines response
        _HeaderFields.Set_locked(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    local procedure CollectFailedQty(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MobToolbox: Codeunit "MOB Toolbox";
        UnableToPickQuantity: Decimal;
    begin
        // Handle only this type
        if _RegistrationType <> 'UnableToReceive' then
            exit;

        if _HeaderFieldValues.GetContextValueAsDecimal('RegisteredQuantity') > 0 then
            Error('Registration for this line has already been completed. Please delete the existing registration and try again.');



        // Create "Decimal Step" to collect the failed quantity
        _Steps.Create_ListStepFromListValues(10, 'UnableToReceiveQuantity', 'Unable to Receive', 'Reason:', 'Please input the Reason you were unable to receive', GetListValue, 'GNA');
        _Steps.Set_optional(true);
    end;

    local procedure GetListValue(): Text[100]
    begin
        exit('GNA' + ';' + '');
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure MyOnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration";
     var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        L_LineNo: Integer;
        L_WarehouseReceiptLine: Record "Warehouse Receipt Line";
        L_PurchaseLine: Record "Purchase Line";
    begin
        // Handle only this type
        if _RegistrationType <> 'UnableToReceive' then
            exit;


        if _IsHandled then
            exit;

        Clear(L_LineNo);
        Evaluate(L_LineNo, _RequestValues.GetValueOrContextValue('LineNumber'));

        L_WarehouseReceiptLine.Reset();
        L_WarehouseReceiptLine.SetRange("No.", _RequestValues.GetValueOrContextValue('OrderBackendId'));
        L_WarehouseReceiptLine.SetRange("Line No.", L_LineNo);
        if L_WarehouseReceiptLine.FindFirst() then begin
            L_WarehouseReceiptLine."Unable to Receive" := _RequestValues.GetValueOrContextValue('UnableToReceiveQuantity');
            L_WarehouseReceiptLine.Modify();


            L_PurchaseLine.Reset();
            L_PurchaseLine.SetRange("Document No.", L_WarehouseReceiptLine."Source No.");
            L_PurchaseLine.SetRange("Document Type", L_PurchaseLine."Document Type"::Order);
            L_PurchaseLine.SetRange("Line No.", L_WarehouseReceiptLine."Source Line No.");
            if L_PurchaseLine.FindFirst() then begin
                L_PurchaseLine."Unable to Receive" := L_WarehouseReceiptLine."Unable to Receive";
                L_PurchaseLine.Modify();
            end;
            _SuccessMessage := 'Completed..'
        end;


        _RegistrationTypeTracking := 'Tracking info for the Document queue.';
        _IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", OnGetReceiveOrderLines_OnSetFilterWarehouseReceiptLine, '', false, false)]
    local procedure OnGetReceiveOrderLines_OnSetFilterWarehouseReceiptLine(var _WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
        _WhseReceiptLine.SetFilter("Unable to Receive", '%1', '');
    end;

    //Filter Header to disply in Receive Header Screen+++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrders_OnSetFilterWarehouseReceipt', '', true, true)]
    local procedure OnGetReceiveOrders_OnSetFilterWarehouseReceipt(var _WhseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        _WhseReceiptHeader.CalcFields("Allowed to Receive");
        _WhseReceiptHeader.SetRange("Allowed to Receive", true);
    end;
}
