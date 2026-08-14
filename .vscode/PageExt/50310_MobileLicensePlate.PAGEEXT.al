pageextension 50310 "MoB License Plate Content Ext" extends "MOB License Plate Content"
{
    layout
    {
        addafter(LotNumber)
        {
            field("Expiration Date"; Rec."Expiration Date")
            {
                ApplicationArea = All;
            }
        }
    }

}