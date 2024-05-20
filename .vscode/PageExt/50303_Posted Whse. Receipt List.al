pageextension 50303 "TC Posted Whse. Receipt List" extends "Posted Whse. Receipt List"
{
    layout
    {
        // Add changes to page layout here
        addlast(Control1)
        {
            field("Curtain Side Vehicle"; Rec."Curtain Side Vehicle")
            {
                ApplicationArea = All;
                Editable = false;
            }
            field("Data Logger Received"; Rec."Data Logger Received")
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