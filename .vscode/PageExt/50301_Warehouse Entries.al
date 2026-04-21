pageextension 50301 "TC Warehouse Entries" extends "Warehouse Entries"
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
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            action(UpdateOrCreateWhseEntry)
            {
                ApplicationArea = All;
                Caption = 'Update/Create Entry';
                Image = EditLines;
                Enabled = AllowCreateEditQty;
                trigger OnAction()
                var
                    WhseEntry: Record "Warehouse Entry";
                    DialogPage: Page "TC Whse Entry Update Dialog";
                    Handler: Codeunit "TC Whse Entry Handler";
                    ActionType: Integer;
                    EntryType: Integer;
                    ItemNo: Code[20];
                    VariantCode: Code[10];
                    LocationCode: Code[10];
                    BinCode: Code[20];
                    Qty: Decimal;
                begin
                    WhseEntry.Get(Rec."Entry No.");
                    DialogPage.SetWarehouseEntry(WhseEntry);
                    if DialogPage.RunModal() = Action::OK then begin
                        ActionType := DialogPage.GetActionType();
                        EntryType := DialogPage.GetEntryType();
                        ItemNo := DialogPage.GetItemNo();
                        VariantCode := DialogPage.GetVariantCode();
                        LocationCode := DialogPage.GetLocationCode();
                        BinCode := DialogPage.GetBinCode();
                        Qty := DialogPage.GetQuantity();
                        Handler.HandleAction(WhseEntry, ActionType, EntryType, ItemNo, VariantCode, LocationCode, BinCode, Qty);
                        CurrPage.Update(false);
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