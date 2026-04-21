pageextension 50300 "TC Item Ledger Entries" extends "Item Ledger Entries"
{

    layout
    {
        // Add changes to page layout here
        addlast(Control1)
        {
            field(Comments; Rec.Comments)
            {
                ApplicationArea = All;
                Editable = false;
                Visible = false;
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(UpdateOrCreateQty)
            {
                ApplicationArea = All;
                Caption = 'Update/Create Qty';
                Image = EditLines;
                Enabled = AllowCreateEditQty;
                trigger OnAction()
                var
                    ItemLedgerEntryRec: Record "Item Ledger Entry";
                    DialogPage: Page "TC Update/Create Qty Dialog";
                    ActionOption: Integer;
                    Qty: Decimal;
                    Handler: Codeunit "TC ILE Qty Handler2";
                begin
                    ItemLedgerEntryRec.Get(Rec."Entry No.");
                    DialogPage.SetItemLedgerEntry(ItemLedgerEntryRec);
                    if DialogPage.RunModal() = Action::OK then begin
                        ActionOption := DialogPage.GetActionOption();
                        Qty := DialogPage.GetQuantity();
                        Handler.HandleAction(ItemLedgerEntryRec, ActionOption, Qty);
                    end;
                end;
            }
        }
    }

    var
        myInt: Integer;
        AllowCreateEditQty: Boolean;

    trigger OnOpenPage()
    var
        UserSetup: Record "User Setup";
    begin
        if UserSetup.Get(UserId()) then
            AllowCreateEditQty := UserSetup."Allow Create/Edit Qty"
        else
            AllowCreateEditQty := false;
    end;
}