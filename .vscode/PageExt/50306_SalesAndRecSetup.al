pageextension 50306 "Sales & Receivable Ext" extends "Sales & Receivables Setup"
{
    layout
    {
        addafter("Archive Orders")
        {
            field("Knapp Doc Queue DateFilter"; Rec."Knapp Doc Queue DateFilter")
            {
                ApplicationArea = All;
            }
            field("Mobile Doc Queue DateFilter"; Rec."Mobile Doc Queue DateFilter")
            {
                ApplicationArea = All;
            }
            field("Auto Pick TOS"; Rec."Auto Pick TOS")
            {
                ApplicationArea = All;
            }
        }
    }
}
