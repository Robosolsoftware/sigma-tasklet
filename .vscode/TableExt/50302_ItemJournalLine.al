tableextension 50302 "Item Journal Line_Ext" extends "Item Journal Line"
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