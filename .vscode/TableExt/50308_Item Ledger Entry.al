tableextension 50308 "Tasklet Item Ledger Entry" extends 32
{
    fields
    {
        // Add changes to table fields here
        field(50300; Comments; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}