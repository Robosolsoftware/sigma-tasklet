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
        // Add changes to page actions here
    }

    var
        myInt: Integer;
}