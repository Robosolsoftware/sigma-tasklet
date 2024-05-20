tableextension 50306 "TC Purch. Rcpt. Header" extends "Purch. Rcpt. Header"
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