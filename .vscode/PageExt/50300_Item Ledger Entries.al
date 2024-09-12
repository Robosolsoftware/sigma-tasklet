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

    var
        myInt: Integer;
}