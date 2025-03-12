tableextension 50312 "General Setup - Channels Ext" extends "Sales & Receivables Setup"
{
    fields
    {
        field(50300; "Knapp Doc Queue DateFilter"; Text[10])
        {
            Caption = 'Clear Knapp Doc Queue Date Filter';
            DataClassification = ToBeClassified;
        }
        field(50301; "Mobile Doc Queue DateFilter"; Text[10])
        {
            Caption = 'Clear Mobile Doc Queue Date Filter';
            DataClassification = ToBeClassified;
        }
        field(50302; "Auto Pick TOS"; Boolean)
        {
            DataClassification = ToBeClassified;
        }
    }
}
