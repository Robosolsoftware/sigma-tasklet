codeunit 50305 "Pick Module"
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;

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


        L_ShippingAgentService.Reset();
        L_ShippingAgentService.SetRange("Shipping Agent Code", _WhseActHeader."Shipping Agent Code");
        L_ShippingAgentService.SetRange(Code, _WhseActHeader."Shipping Agent Service Code");
        if L_ShippingAgentService.FindFirst() then begin
            _BaseOrderElement.Set_DisplayLine3(_BaseOrderElement.Get_DisplayLine3() + mobtool.CRLFSeparator() + 'Departure Time: ' + Format(L_ShippingAgentService."Departure Time"))
        end;

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

        _HeaderFields.Create_TextField(17, 'AgentServiceCode', 'Service Code');
        _HeaderFields.Set_optional(true);
        _HeaderFields.Save();
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
            'AgentServiceCode':
                begin
                    if _HeaderFilter.Value <> '' then begin
                        _WhseActHeader.SetRange("Shipping Agent Service Code", _HeaderFilter.Value);
                    end;
                end;
        end;
    end;
}