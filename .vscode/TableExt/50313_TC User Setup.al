tableextension 50313 "TC User Setup" extends "User Setup"
{
    fields
    {
        field(50300; "Allow Create/Edit Qty"; Boolean)
        {
            DataClassification = ToBeClassified;
            Caption = 'Allow Create/Edit Qty';
            Description = 'Allows users to create or edit quantities in Item Ledger Entries and Warehouse Entries';
        }
    }
}
