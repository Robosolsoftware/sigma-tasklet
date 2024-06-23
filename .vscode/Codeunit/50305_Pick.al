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
    begin
        if _BaseOrderElement.Get_DisplayLine5() <> '' then
            _BaseOrderElement.Set_DisplayLine5(_BaseOrderElement.Get_DisplayLine5() + mobtool.CRLFSeparator() + 'Work Description: ' + _WhseActHeader."Work Description")
        else
            _BaseOrderElement.Set_DisplayLine5('Work Description: ' + _WhseActHeader."Work Description");

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnGetPickOrderLines_OnAfterSetFromWarehouseActivityLine', '', false, false)]
    local procedure OnGetPickOrderLines_OnAfterSetFromWarehouseActivityLine(_WhseActLineTake: Record "Warehouse Activity Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        mobtool: Codeunit "MOB Toolbox";
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
                    _BaseOrderLineElement.Set_DisplayLine4(StrSubstNo('Variant Code : %1', _WhseActLineTake."Variant Code"));

                    _BaseOrderLineElement.Modify();
                end;
        end;
    end;
}