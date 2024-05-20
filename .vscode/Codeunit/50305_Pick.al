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
}