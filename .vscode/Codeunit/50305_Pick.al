codeunit 50305 "Pick Module"
{
    SingleInstance = true;
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;
        CalledFromScanner: Boolean;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnGetPickOrders_OnAfterSetFromWarehouseActivityHeader', '', false, false)]
    local procedure OnGetPickOrders_OnAfterSetFromWarehouseActivityHeader(_WhseActHeader: Record "Warehouse Activity Header"; var _BaseOrderElement: Record "MOB Ns BaseDataModel Element")
    var
        mobtool: Codeunit "MOB Toolbox";
        L_ShippingAgentService: Record "Shipping Agent Services";
    begin
        _WhseActHeader.CalcFields("Shipping Agent Code", "Shipping Agent Service Code");

        if _BaseOrderElement.Get_DisplayLine5() <> '' then
            _BaseOrderElement.Set_DisplayLine5(_BaseOrderElement.Get_DisplayLine5() + mobtool.CRLFSeparator() + 'Work Description: ' + _WhseActHeader."Work Description")
        else
            _BaseOrderElement.Set_DisplayLine5('Work Description: ' + _WhseActHeader."Work Description");


        if _BaseOrderElement.Get_DisplayLine3() <> '' then
            _BaseOrderElement.Set_DisplayLine3(_BaseOrderElement.Get_DisplayLine3() + mobtool.CRLFSeparator() + 'Service Code: ' + _WhseActHeader."Shipping Agent Service Code")
        else
            _BaseOrderElement.Set_DisplayLine3('Service Code: ' + _WhseActHeader."Shipping Agent Service Code");


        /*L_ShippingAgentService.Reset();
        L_ShippingAgentService.SetRange("Shipping Agent Code", _WhseActHeader."Shipping Agent Code");
        L_ShippingAgentService.SetRange(Code, _WhseActHeader."Shipping Agent Service Code");
        if L_ShippingAgentService.FindFirst() then begin
            _BaseOrderElement.Set_DisplayLine3(_BaseOrderElement.Get_DisplayLine3() + mobtool.CRLFSeparator() + 'Departure Time: ' + Format(L_ShippingAgentService."Departure Time"))
        end;*/
        _BaseOrderElement.Set_DisplayLine3(_BaseOrderElement.Get_DisplayLine3() + mobtool.CRLFSeparator() + 'Departure Time: ' + Format(_WhseActHeader."Departure Time"))

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnGetPickOrderLines_OnAfterSetFromWarehouseActivityLine', '', false, false)]
    local procedure OnGetPickOrderLines_OnAfterSetFromWarehouseActivityLine(_WhseActLineTake: Record "Warehouse Activity Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        mobtool: Codeunit "MOB Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        case _WhseActLineTake."Activity Type" of
            _WhseActLineTake."Activity Type"::Pick:
                begin
                    //Add "Variant Code"++
                    _BaseOrderLineElement.Set_DisplayLine4(StrSubstNo('Variant Code : %1', _WhseActLineTake."Variant Code"));

                    _BaseOrderLineElement.Modify();
                end;
            _WhseActLineTake."Activity Type"::"Invt. Pick":
                begin
                    //Add "Variant Code"++
                    _BaseOrderLineElement.Set_DisplayLine4(StrSubstNo('Variant Code : %1', _WhseActLineTake."Variant Code") + MobToolbox.CRLFSeparator() + 'Unable to Pick: ' + _WhseActLineTake."Unable to Pick");

                    _BaseOrderLineElement.Modify();
                end;
        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]

    local procedure GetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    var
        Options: List of [Text];
        tes: Record "Warehouse Activity Header";
    begin
        _HeaderFields.InitConfigurationKey('PickOrderFilters');
        _HeaderFields.Create_ListFieldFromListValues(15, 'TypeFilter', 'Source Type', 'Sales Order;Transfer Order;Purchase Return Order;ALL', 'Sales Order');
        _HeaderFields.Set_optional(true);
        _HeaderFields.Save();

        //_HeaderFields.Create_IntegerField(16, 'SourceNo', 'Source No');
        _HeaderFields.Create_TextField(16, 'SourceNo', 'Inv. Pick No.');
        _HeaderFields.Set_optional(true);
        _HeaderFields.Save();

        _HeaderFields.Create_TextField(17, 'ShipmentDate', 'Shipment Date');
        _HeaderFields.Set_optional(true);
        _HeaderFields.Save();


        _HeaderFields.Create_ListFieldFromDataTable(30000, 'ShippingAgentCode', 'Shipping Agent Code', 'ShippingAgent', 'Code', 'Code', '');
        _HeaderFields.Set_optional(true);


    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnGetPickOrders_OnAfterSetFromWarehouseActivityHeader', '', true, true)]
    local procedure My02GetPickOrders_OnAfterSetFromWarehouseActivityHeader(_WhseActHeader: Record "Warehouse Activity Header"; var _BaseOrderElement: Record "MOB Ns BaseDataModel Element")
    begin
        _BaseOrderElement.SetValue('DepartureTime', 'Departure Time: ' + Format(_WhseActHeader."Departure Time"));
        _BaseOrderElement.Set_Sorting1(_BaseOrderElement.GetValue('DepartureTime'));
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnGetPickOrders_OnSetFilterWarehouseActivity', '', false, false)]
    local procedure OnGetPickOrders_OnSetFilterWarehouseActivity(_HeaderFilter: Record "MOB NS Request Element"; var _WhseActHeader: Record "Warehouse Activity Header"; var _WhseActLine: Record "Warehouse Activity Line")
    var
        L_warehouseLine: Record "Warehouse Activity Line";
        TypeFilter: Code[50];
    begin
        case _HeaderFilter."Name" of
            'TypeFilter':
                begin
                    if _HeaderFilter."Value" <> 'All' then begin
                        if _HeaderFilter.Value = 'Sales Order' then
                            _WhseActHeader.SetRange(_SourceDocument, _WhseActHeader._SourceDocument::"Sales Order");

                        if _HeaderFilter.Value = 'Transfer Order' then
                            _WhseActHeader.SetRange(_SourceDocument, _WhseActHeader._SourceDocument::"Outbound Transfer");

                        if _HeaderFilter.Value = 'Purchase Return Order' then
                            _WhseActHeader.SetRange(_SourceDocument, _WhseActHeader._SourceDocument::"Purchase Return Order");

                    end;

                end;
            'SourceNo':
                begin
                    if _HeaderFilter.Value <> '' then begin
                        _WhseActHeader.SetRange("No.", _HeaderFilter.Value);

                        // L_warehouseLine.Reset();
                        // L_warehouseLine.SetRange("Source No.", _HeaderFilter.Value);
                        // L_warehouseLine.SetFilter("Activity Type", '%1|%2', L_warehouseLine."Activity Type"::Pick, L_warehouseLine."Activity Type"::"Invt. Pick");
                        // if L_warehouseLine.FindFirst() then begin
                        //     _WhseActHeader.SetRange("No.", L_warehouseLine."No.");
                        // end else
                        //     Error('Order does not exist');
                    end;
                end;
            'ShippingAgentCode':
                begin
                    if _HeaderFilter.Value <> '' then begin
                        _WhseActHeader.SetRange("Shipping Agent Code", _HeaderFilter.Value);
                    end;
                end;
            'ShipmentDate':
                begin
                    if _HeaderFilter.Value <> '' then begin
                        _WhseActHeader.SetFilter("Shipment Date", _HeaderFilter.Value);
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddDataTables', '', true, true)]
    procedure My02OnGetReferenceData_OnAddDataTables(var _DataTable: Record "MOB DataTable Element")
    var
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentService: Record "Shipping Agent Services";
        test: Record "MOB WMS Registration";
    begin
        _DataTable.InitDataTable('ShippingAgent');
        _DataTable.Create();
        _DataTable.SetValue('Code', '');
        _DataTable.SetValue('Name', ' ');
        ShippingAgent.Reset();
        if ShippingAgent.FindFirst() then begin
            repeat
                _DataTable.Create();
                _DataTable.SetValue('Code', ShippingAgent.Code);
                _DataTable.SetValue('Name', ShippingAgent.Name);
            until ShippingAgent.Next() = 0;
        end;
    end;


    #Region User story - 25735 - Ability to change variant on Tasklet
    //Add Step to Enter Variant code++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnGetPickOrderLines_OnAddStepsToAnyLine', '', true, true)]
    local procedure OnGetPickOrderLines_OnAddStepsToAnyLine(var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element"; _RecRef: RecordRef; var _Steps: Record "MOB Steps Element")
    var
        L_WarehouseActivityLine: Record "Warehouse Activity Line";
        L_Item: Record Item;
    begin
        L_WarehouseActivityLine.Reset();
        _RecRef.SetTable(L_WarehouseActivityLine);

        if L_WarehouseActivityLine."Activity Type" = L_WarehouseActivityLine."Activity Type"::"Invt. Pick" then begin
            L_Item.Reset();
            L_Item.SetRange("No.", L_WarehouseActivityLine."Item No.");
            if L_Item.FindFirst() then begin
                if L_Item."Variant Mandatory if Exists" <> L_Item."Variant Mandatory if Exists"::No then begin
                    _Steps.Create_ListStep_Variant(1, L_WarehouseActivityLine."Item No.");
                    _Steps.Set_defaultValue(L_WarehouseActivityLine."Variant Code");


                    // // Enabled Online Validation and setting a DocumentType
                    // _Steps.Set_onlineValidation('ValidateMyVarintStep', true);
                end;
            end;
        end;
    end;

    // // Add Mobile DocumentType to handle validation code
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Setup Doc. Types", 'OnAfterCreateDefaultDocumentTypes', '', true, true)]
    // local procedure My03OnAfterCreateDefaultDocumentTypes()
    // var
    //     MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    // begin
    //     MobWmsSetupDocTypes.CreateDocumentType('ValidateMyVarintStep', '', Codeunit::"MOB WMS Whse. Inquiry");
    // end;

    // // Implement DocumentType
    // [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Whse. Inquiry", 'OnWhseInquiryOnCustomDocumentType', '', true, true)]
    // local procedure My03OnWhseInquiryOnCustomDocumentType(_DocumentType: Text; var _RequestValues: Record "MOB NS Request Element"; var _ResponseElement: Record "MOB NS Resp Element"; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    // begin
    //     if _IsHandled then
    //         exit;

    //     if _DocumentType = 'ValidateMyVarintStep' then
    //         Error('MyTextStep: %1\ OrderNo: %2\ LineNo: %3',
    //           _RequestValues.GetValue('Variant'),
    //           _RequestValues.Get_BackendID(),
    //           _RequestValues.Get_LineNumber());

    //     _IsHandled := true;
    // end;
    // //Check Free quantity Validatio------


    //Update New Variant On Sales line++++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnHandleRegistrationForWarehouseActivityLine', '', true, true)]
    local procedure OnPostPickOrder_OnHandleRegistrationForWarehouseActivityLine(var _Registration: Record "MOB WMS Registration"; var _WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        L_SalesLine: Record "Sales Line";
    begin
        Clear(CalledFromScanner);

        if _WarehouseActivityLine."Activity Type" = _WarehouseActivityLine."Activity Type"::"Invt. Pick" then begin
            L_SalesLine.Reset();
            if _WarehouseActivityLine."Source Document" = _WarehouseActivityLine."Source Document"::"Sales Order" then
                L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
            L_SalesLine.SetRange("Document No.", _WarehouseActivityLine."Source No.");
            L_SalesLine.SetRange("Line No.", _WarehouseActivityLine."Source Line No.");
            if L_SalesLine.FindFirst() then begin
                if _Registration.GetValue('Variant') <> '' then begin
                    if L_SalesLine."Variant Code" <> _Registration.GetValue('Variant') then begin
                        CalledFromScanner := true;
                        //Update Sales line+++
                        L_SalesLine.Validate("Variant Code", _Registration.GetValue('Variant'));
                        L_SalesLine.Modify();
                    end;
                    // //Update on Inv Pick Line++
                    // if _WarehouseActivityLine."Variant Code" <> _Registration.GetValue('Variant') then begin
                    //     CalledFromScanner := true;
                    //     _WarehouseActivityLine.Validate("Variant Code", _Registration.GetValue('Variant'));
                    //     _WarehouseActivityLine.Modify();
                    // end;
                end;
            end;
        end;
    end;

    //Update New Variant On Warehouse activity line++++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnPostPickOrder_OnBeforeRunWhseActivityPost', '', false, false)]
    local procedure OnPostPickOrder_OnBeforeRunWhseActivityPost(var _WhseActLinesToPost: Record "Warehouse Activity Line")
    var
        L_SalesLine: Record "Sales Line";
    begin
        if _WhseActLinesToPost.FindSet() then begin
            repeat
                L_SalesLine.Reset();
                L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
                L_SalesLine.SetRange("Document No.", _WhseActLinesToPost."Source No.");
                L_SalesLine.SetRange("Line No.", _WhseActLinesToPost."Source Line No.");
                if L_SalesLine.FindFirst() then begin
                    if L_SalesLine."Variant Code" <> _WhseActLinesToPost."Variant Code" then begin
                        _WhseActLinesToPost.Validate("Variant Code", L_SalesLine."Variant Code");
                        _WhseActLinesToPost.Modify();
                    end;
                end;
            until _WhseActLinesToPost.Next() = 0;
        end;
    end;



    //Removed Default Open Status Check+++++++
    //Step1++
    [EventSubscriber(ObjectType::Table, Database::"Sales Line", 'OnBeforeTestStatusOpen', '', false, false)]
    local procedure OnBeforeTestStatusOpen(CallingFieldNo: Integer; var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
        //Check to ignore Status Validation from Scanner at the time of change Variant Code+++
        if CalledFromScanner = true then begin
            if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then begin
                if CallingFieldNo = 0 then begin
                    IsHandled := true;
                end;
            end;
        end;
    end;

    //Step2++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnBeforeVerifyFieldNotChanged', '', false, false)]
    local procedure OnBeforeVerifyFieldNotChanged(FieldNumber: Integer; var IsHandled: Boolean)
    begin
        //Check to ignore Status Validation from Scanner at the time of change Variant Code+++
        if FieldNumber = 5402 then begin
            if CalledFromScanner = true then begin
                IsHandled := true;
            end;
            CalledFromScanner := false;
        end;
    end;
    //Removed Default Open Status Check+++++++


    //Revert sales Line Changes if posting failed++++
    [EventSubscriber(ObjectType::Table, Database::"MOB WMS Registration", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure MOBRegistraion_OnAfterDeleteEvent(var Rec: Record "MOB WMS Registration")
    var
        L_MOBRegistration: Record "MOB WMS Registration";
        L_SalesLine: Record "Sales Line";
        L_WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        L_MOBRegistration.Reset();
        L_MOBRegistration.SetRange("Posting MessageId", Rec."Posting MessageId");
        L_MOBRegistration.SetCurrentKey("Order No.");
        L_MOBRegistration.Ascending(true);
        if L_MOBRegistration.FindSet() then begin
            repeat
                if L_MOBRegistration.Type = L_MOBRegistration.Type::Pick then begin
                    L_WarehouseActivityLine.Reset();
                    L_WarehouseActivityLine.SetRange("No.", L_MOBRegistration."Order No.");
                    L_WarehouseActivityLine.SetRange("Line No.", L_MOBRegistration."Line No.");
                    if L_WarehouseActivityLine.FindFirst() then begin
                        L_SalesLine.Reset();
                        L_SalesLine.SetRange("Document Type", L_SalesLine."Document Type"::Order);
                        L_SalesLine.SetRange("Document No.", L_WarehouseActivityLine."Source No.");
                        L_SalesLine.SetRange("Line No.", L_WarehouseActivityLine."Source Line No.");
                        if L_SalesLine.FindFirst() then begin
                            if L_SalesLine."Variant Code" <> L_MOBRegistration."Variant Code" then begin
                                CalledFromScanner := true;

                                L_SalesLine.Validate("Variant Code", L_MOBRegistration."Variant Code");
                                L_SalesLine.Modify();
                                Commit();
                            end;
                        end;
                    end;
                end;
            until L_MOBRegistration.Next() = 0;
        end;
    end;
    #EndRegion ++++


}