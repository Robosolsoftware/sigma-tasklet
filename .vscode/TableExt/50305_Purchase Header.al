tableextension 50305 "TC Purchase Header" extends "Purchase Header"
{
    fields
    {
        // Add changes to table fields here
        field(50300; "Clear Filter"; Code[20])
        {
            DataClassification = ToBeClassified;
            //Dont use this field as this is for removing filter in tasklet++
        }
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