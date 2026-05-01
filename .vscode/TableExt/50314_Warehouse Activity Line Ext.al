tableextension 50314 "TC Warehouse Activity Line" extends "Warehouse Activity Line"
{
    fields
    {
        field(50300; "Custom Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
    }
}
