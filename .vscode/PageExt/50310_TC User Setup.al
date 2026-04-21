pageextension 50312 "TC User Setup" extends "User Setup"
{
    layout
    {
        addlast(Control1)
        {
            field("Allow Create/Edit Qty"; Rec."Allow Create/Edit Qty")
            {
                ApplicationArea = All;
                Caption = 'Allow Create/Edit Qty';
                ToolTip = 'Allow user to create or edit quantities in Item Ledger Entries and Warehouse Entries';
            }
        }
    }
}
