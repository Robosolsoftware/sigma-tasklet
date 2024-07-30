pageextension 50304 "TC MOB Reports" extends "MOB Reports"
{
    layout
    {
        // Add changes to page layout here
        addafter(Enabled)
        {
            field("Auto Print"; Rec."Auto Print")
            {
                ApplicationArea = All;
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