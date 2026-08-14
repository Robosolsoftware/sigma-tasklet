codeunit 50314 LicensePlateManagement
{
    trigger OnRun()
    begin

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB License Plate Mgt", 'OnBeforeInsertLPContent_OnAddRegistrationToLicensePlate', '', true, true)]
    local procedure OnAddRegistrationToLicensePlate(var _Registration: Record "MOB WMS Registration"; var _LicensePlateContent: Record "MOB License Plate Content")
    var
        Location: Record Location;
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        ExpDate: Date;
    begin
        if _LicensePlateContent."Lot No." = '' then
            exit;

        if _Registration."Expiration Date" <> 0D then begin
            _LicensePlateContent."Expiration Date" := _Registration."Expiration Date";
            exit;
        end;

        if not Location.Get(_LicensePlateContent."Location Code") then
            exit;

        Clear(MobTrackingSetup);
        MobTrackingSetup."Serial No." := _LicensePlateContent."Serial No.";
        MobTrackingSetup."Lot No." := _LicensePlateContent."Lot No.";
        MobTrackingSetup."Package No." := _LicensePlateContent."Package No.";

        MobItemTrackingManagement.GetWhseExpirationDate(_LicensePlateContent."No.", _LicensePlateContent."Variant Code", Location, MobTrackingSetup, ExpDate);

        _LicensePlateContent."Expiration Date" := ExpDate;
    end;

    var
        myInt: Integer;
}