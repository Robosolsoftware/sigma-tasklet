codeunit 50301 "PutAway Module"
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Put Away", 'OnGetPutAwayOrderLines_OnAfterSetFromWarehouseActivityLine', '', false, false)]
    local procedure OnGetPutAwayOrderLines_OnAfterSetFromWarehouseActivityLine(_WhseActLineTake: Record "Warehouse Activity Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        MobToolbox: Codeunit "MOB Toolbox";
        ItemVariant: Record "Item Variant";
    begin
        case _WhseActLineTake."Activity Type" of
            _WhseActLineTake."Activity Type"::"Put-away":
                begin
                    //Remove Sugessted To Bin Code++
                    _BaseOrderLineElement.Set_ToBin('');


                    ItemVariant.Reset();
                    ItemVariant.SetRange(Code, _WhseActLineTake."Variant Code");
                    ItemVariant.SetRange("Item No.", _WhseActLineTake."Item No.");
                    if ItemVariant.FindFirst() then
                        _BaseOrderLineElement.Set_DisplayLine4(StrSubstNo('Variant Code : %1 Priority : %2', _WhseActLineTake."Variant Code", ItemVariant.Priority))
                    else
                        //Add "Variant Code"++
                        _BaseOrderLineElement.Set_DisplayLine4(StrSubstNo('Variant Code : %1', _WhseActLineTake."Variant Code"));

                    _BaseOrderLineElement.Modify();
                end;
            _WhseActLineTake."Activity Type"::"Invt. Put-away":
                begin
                    //Remove Sugessted To Bin Code++
                    _BaseOrderLineElement.Set_ToBin('');

                    ItemVariant.Reset();
                    ItemVariant.SetRange(Code, _WhseActLineTake."Variant Code");
                    ItemVariant.SetRange("Item No.", _WhseActLineTake."Item No.");
                    if ItemVariant.FindFirst() then
                        //Add "Variant Code"++
                        _BaseOrderLineElement.Set_DisplayLine4(StrSubstNo('Variant Code : %1 Priority : %2', _WhseActLineTake."Variant Code", ItemVariant.Priority))
                    else
                        _BaseOrderLineElement.Set_DisplayLine4(StrSubstNo('Variant Code : %1', _WhseActLineTake."Variant Code"));

                    _BaseOrderLineElement.Modify();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Put Away", 'OnGetPutAwayOrders_OnAfterSetFromWarehouseActivityHeader', '', false, false)]
    local procedure OnGetPutAwayOrders_OnAfterSetFromWarehouseActivityHeader(_WhseActHeader: Record "Warehouse Activity Header"; var _BaseOrderElement: Record "MOB Ns BaseDataModel Element")
    var
        mobtool: Codeunit "MOB Toolbox";
        user: Record User;
    begin
        user.Reset();
        user.SetRange("User Security ID", _WhseActHeader.SystemCreatedBy);
        if user.FindFirst() then
            _BaseOrderElement.Set_DisplayLine3('Created by: ' + user."User Name" + mobtool.CRLFSeparator() + 'Created At: ' + format(_WhseActHeader.SystemCreatedAt));

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]

    local procedure GetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    var
        Options: List of [Text];
    begin
        _HeaderFields.InitConfigurationKey('PutAwayOrderFilters');
        _HeaderFields.Create_ListFieldFromListValues(15, 'TypeFilter', 'Source Type', 'Purchase Order;Transfer Order;ALL', 'Purchase Order');
        _HeaderFields.Set_optional(true);
        _HeaderFields.Save();

        //_HeaderFields.Create_IntegerField(16, 'SourceNo', 'Source No');
        _HeaderFields.Create_TextField(16, 'SourceNo', 'Source No');
        _HeaderFields.Set_optional(true);
        _HeaderFields.Save();

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Put Away", 'OnGetPutAwayOrders_OnSetFilterWarehouseActivity', '', false, false)]
    local procedure OnGetPutAwayOrders_OnSetFilterWarehouseActivity(_HeaderFilter: Record "MOB NS Request Element"; var __WhseActivityLine: Record "Warehouse Activity Line"; var _WhseActivityHeader: Record "Warehouse Activity Header")
    var
        L_warehouseLine: Record "Warehouse Activity Line";
        TypeFilter: Code[50];
    begin
        case _HeaderFilter."Name" of
            'TypeFilter':
                begin
                    if _HeaderFilter."Value" <> 'All' then begin
                        if _HeaderFilter.Value = 'Purchase Order' then
                            _WhseActivityHeader.SetRange(_SourceDocument, _WhseActivityHeader._SourceDocument::"Purchase Order");


                        if _HeaderFilter.Value = 'Transfer Order' then
                            _WhseActivityHeader.SetRange(_SourceDocument, _WhseActivityHeader._SourceDocument::"Inbound Transfer");

                    end;

                end;
            'SourceNo':
                begin
                    if _HeaderFilter.Value <> '' then begin
                        L_warehouseLine.Reset();
                        L_warehouseLine.SetRange("Source No.", _HeaderFilter.Value);
                        L_warehouseLine.SetFilter("Activity Type", '%1|%2', L_warehouseLine."Activity Type"::"Put-away", L_warehouseLine."Activity Type"::"Invt. Put-away");
                        if L_warehouseLine.FindFirst() then begin
                            _WhseActivityHeader.SetRange("No.", L_warehouseLine."No.");
                        end else
                            Error('Order does not exist');
                    end;
                end;

        end;
    end;

}