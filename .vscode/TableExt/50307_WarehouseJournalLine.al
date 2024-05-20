tableextension 50307 "Warehouse Journal Line" extends "Warehouse Journal Line"
{
    fields
    {
        // Add changes to table fields here
        field(50300; Comments; Text[2048])
        {
            DataClassification = ToBeClassified;
        }
        field(50301; "Item Image"; Blob)
        {
            DataClassification = ToBeClassified;
        }
    }

    var
        myInt: Integer;
}