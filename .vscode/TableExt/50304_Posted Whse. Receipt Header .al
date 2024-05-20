tableextension 50304 "TC Posted Whse. RCPT Header" extends "Posted Whse. Receipt Header"
{
    fields
    {
        // Add changes to table fields here
        field(50301; "Curtain Side Vehicle"; Boolean)
        {

        }
        field(50302; "Data Logger Received"; Boolean)
        {

        }
    }

    var
        myInt: Integer;
}