codeunit 50308 "Count Module"
{
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;

    //Display Variant Code on Count line++ 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Count", 'OnGetCountOrderLines_OnAfterSetFromItemJournalLine', '', false, false)]
    local procedure OnGetCountOrderLines_OnAfterSetFromItemJournalLine(_ItemJnlLine: Record "Item Journal Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        MobToolbox: Codeunit "MOB Toolbox";
    begin
        if _BaseOrderLineElement.Get_DisplayLine3() <> '' then begin
            _BaseOrderLineElement.Set_DisplayLine3(_BaseOrderLineElement.Get_DisplayLine3() + MobToolbox.CRLFSeparator() + 'Variant Code: ' + _ItemJnlLine."Variant Code");
            _BaseOrderLineElement.Modify();
        end else begin
            _BaseOrderLineElement.Set_DisplayLine3('Variant Code: ' + _ItemJnlLine."Variant Code");
            _BaseOrderLineElement.Modify();
        end;
    end;
}