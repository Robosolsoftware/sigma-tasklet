tableextension 50301 MyExtension extends "Warehouse Entry"
{
    fields
    {
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