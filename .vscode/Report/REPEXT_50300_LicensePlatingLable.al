reportextension 50300 LicensePlatingLabelEXT extends "MOB License Plate Label"
{
    dataset
    {

    }

    requestpage
    {

    }

    rendering
    {
        layout("License Plate Label GS1 4x4")
        {
            Type = RDLC;
            Caption = 'License Plate Label GS1 4x4';
            LayoutFile = 'License Plate Label GS1 4x4.rdl';
        }
    }
}