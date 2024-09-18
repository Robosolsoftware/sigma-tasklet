codeunit 50309 "Unable to Pick"
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure MynGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        _HeaderFields.InitConfigurationKey('UnableToPick'); // Name of Header

        // Add Header fields
        // Using pre-defined helper-functions makes it easy to transfer values as field names match 100%
        _HeaderFields.Create_TextField_OrderBackendID(10);
        _HeaderFields.Set_locked(true);

        _HeaderFields.Create_ListField_Location(11);    // 'Location' is a known field on OrderLines response
        _HeaderFields.Set_locked(true);

        _HeaderFields.Create_TextField_FromBin(20);     // 'FromBin' is a known field on OrderLines response
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
        if _RegistrationType <> 'UnableToPick' then
            exit;

        if _HeaderFieldValues.GetContextValueAsDecimal('RegisteredQuantity') > 0 then
            Error('Registration for this line has already been completed. Please delete the existing registration and try again.');



        // Create "Decimal Step" to collect the failed quantity
        _Steps.Create_ListStepFromListValues(10, 'UnableToPickQuantity', 'Unable to pick', 'Reason:', 'Please input the Reason you were unable to pick', GetListValue, 'TOS');
        _Steps.Set_optional(true);
    end;

    local procedure GetListValue(): Text[100]
    begin
        exit('TOS' + ';' + 'Damaged' + ';' + '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure MyOnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration";
     var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        L_WarehouseActivityLine: Record "Warehouse Activity Line";
        L_LineNo: Integer;
        L_SalesLine: Record "Sales Line";
    begin
        // Handle only this type
        if _RegistrationType <> 'UnableToPick' then
            exit;


        if _IsHandled then
            exit;

        Clear(L_LineNo);
        Evaluate(L_LineNo, _RequestValues.GetValueOrContextValue('LineNumber'));

        L_WarehouseActivityLine.Reset();
        L_WarehouseActivityLine.SetRange("No.", _RequestValues.GetValueOrContextValue('OrderBackendId'));
        L_WarehouseActivityLine.SetRange("Line No.", L_LineNo);
        if L_WarehouseActivityLine.FindFirst() then begin
            L_WarehouseActivityLine."Unable to Pick" := _RequestValues.GetValueOrContextValue('UnableToPickQuantity');
            L_WarehouseActivityLine.Modify();


            L_SalesLine.Reset();
            L_SalesLine.SetRange("Document No.", L_WarehouseActivityLine."Source No.");
            L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
            L_SalesLine.SetRange("Line No.", L_WarehouseActivityLine."Source Line No.");
            if L_SalesLine.FindFirst() then begin
                L_SalesLine."Unable to Pick" := L_WarehouseActivityLine."Unable to Pick";
                L_SalesLine.Modify();
            end;
            _SuccessMessage := 'Completed..'
        end;


        _RegistrationTypeTracking := 'Tracking info for the Document queue.';
        _IsHandled := true;
    end;



    //Filter Line to disply in Pick Line Screen+++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnGetPickOrderLines_OnSetFilterWarehouseActivityLine', '', true, true)]
    local procedure MyOnGetPickOrderLines_OnSetFilterWarehouseActivityLine(var _WhseActLineTake: Record "Warehouse Activity Line")
    begin
        _WhseActLineTake.SetFilter("Unable to Pick", '%1', '');
    end;


    //Filter Header to disply in Pick Header Screen+++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnGetPickOrders_OnSetFilterWarehouseActivity', '', true, true)]
    local procedure OnGetPickOrders_OnSetFilterWarehouseActivity(var _WhseActHeader: Record "Warehouse Activity Header")
    begin
        _WhseActHeader.CalcFields("Allowed to Pick");
        _WhseActHeader.SetRange("Allowed to Pick", true);
    end;

    //Check before posting++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnBeforePostWarehouseActivityOrder', '', false, false)]
    local procedure OnPostPickOrder_OnBeforePostWarehouseActivityOrder(var _WhseActivityHeader: Record "Warehouse Activity Header")
    var
        L_WarehouseActivityLine: Record "Warehouse Activity Line";
        L_MobRegistration: Record "MOB WMS Registration";
    begin
        if (_WhseActivityHeader."Source Document" <> _WhseActivityHeader."Source Document"::"Outbound Transfer") then begin
            L_WarehouseActivityLine.Reset();
            L_WarehouseActivityLine.SetRange("No.", _WhseActivityHeader."No.");
            L_WarehouseActivityLine.SetRange("Activity Type", _WhseActivityHeader.Type);
            L_WarehouseActivityLine.SetRange("Action Type", L_WarehouseActivityLine."Action Type"::Take);
            L_WarehouseActivityLine.SetRange("Unable to Pick", '');
            if L_WarehouseActivityLine.FindSet() then begin
                repeat
                    L_MobRegistration.Reset();
                    L_MobRegistration.SetRange(Type, L_MobRegistration.Type::Pick);
                    L_MobRegistration.SetRange("Order No.", L_WarehouseActivityLine."No.");
                    L_MobRegistration.SetRange("Source MOBSystemId", L_WarehouseActivityLine.MOBSystemID);
                    L_MobRegistration.SetRange(Handled, false);
                    if not L_MobRegistration.FindFirst() then
                        Error('You cannot post because one of the line registrations is still pending. Order No.: %1. Line No.: %2. Item No.: %3', L_WarehouseActivityLine."No.", L_WarehouseActivityLine."Line No.", L_WarehouseActivityLine."Item No.");
                until L_WarehouseActivityLine.Next() = 0;
            end;
        end;
    end;

    //Delete Inv. Pick After Posting++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnAfterPostAnyOrder', '', false, false)]
    local procedure OnPostPickOrder_OnAfterPostAnyOrder(var _OrderValues: Record "MOB Common Element"; var _RecRef: RecordRef; var _ResultMessage: Text)
    var
        L_WarehouseActivityLine: Record "Warehouse Activity Line";
        L_WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        L_WarehouseActivityLine.Reset();
        _RecRef.SetTable(L_WarehouseActivityLine);
        if L_WarehouseActivityLine.FindFirst() then begin
            L_WarehouseActivityHeader.Reset();
            L_WarehouseActivityHeader.SetRange("No.", L_WarehouseActivityLine."No.");
            L_WarehouseActivityHeader.SetRange(Type, L_WarehouseActivityLine."Activity Type");
            if L_WarehouseActivityHeader.FindFirst() then begin
                if (L_WarehouseActivityHeader."Source Document" <> L_WarehouseActivityHeader."Source Document"::"Outbound Transfer") then
                    L_WarehouseActivityHeader.Delete(true);
            end;
        end;
    end;



}