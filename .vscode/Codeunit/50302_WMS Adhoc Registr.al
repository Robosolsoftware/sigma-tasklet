codeunit 50302 "WMS Adhoc Registr"
{
    SingleInstance = true;
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;
        G_WarehouseEntryNo: Integer;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAfterAddStep', '', true, true)]
    procedure OnGetRegistrationConfiguration_OnAfterAddStep(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Step: Record "MOB Steps Element")
    var
        Location: Record Location;
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobReferenceData: Codeunit "MOB WMS Reference Data";
        LocationCode: Code[10];
        ItemNo: Code[20];
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";
    begin

        //Adjust Quantity++
        if _RegistrationType = MobWmsToolbox."CONST::AdjustQuantity"() then begin
            if _Step.Get_name() = 'ReasonCode' then begin
                _Step.Set_visible(false);
                _Step.Modify();
            end;

        end;
    end;

    //Add line function++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    procedure OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        Location: Record Location;
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobReferenceData: Codeunit "MOB WMS Reference Data";
        LocationCode: Code[10];
        ItemNo: Code[20];
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        te: Codeunit 23;

    begin

        //Unplanned Count and Adjust Qty++
        Clear(ItemNo);
        if (_RegistrationType = MobWmsToolbox."CONST::UnplannedCount"()) OR (_RegistrationType = MobWmsToolbox."CONST::AdjustQuantity"()) then begin
            Evaluate(ItemNo, _HeaderFieldValues.GetValue('Item'));
            _Steps.Create_ListStepFromListValues(50000, 'CustReasonCode', StrSubstNo('Item %1 - Reason', ItemNo), 'Reason Code:', 'Select Reason Code', GetReasonCode(), '');
            // _Steps.Set_header(MobWmsLanguage.GetMessage('ITEM') + ' ' + ItemNo + ' - ' + 'Reason Code');
            // _Steps.Set_label('Reason Code:');
            // _Steps.Set_helpLabel('Select Reason Code');
            _Steps.Set_autoForwardAfterScan(true);
            // _Steps.Set_optional(false);
            // _Steps.Set_defaultValue('');
            // _Steps.Set_length(20);
            // _Steps.Set_labelWidth_WindowsMobile(100);


        end;
        //Unplanned Count and Adjust Qty--


        //Adjust Qty++
        if (_RegistrationType = MobWmsToolbox."CONST::AdjustQuantity"()) then begin
            // Step: Comments
            _Steps.Create_MultiLineTextStep(50001, 'Comments', 'Comments');
            _Steps.Set_optional(true);
            _Steps.Set_helpLabel('Enter Comments');

            // Step: ImageCapture
            _Steps.Create_ImageCaptureStep(50002, 'ImageCapture');
            _Steps.Set_header(MobWmsLanguage.GetMessage('ADD_IMAGE'));
            _Steps.Set_listSeparator(';');
            _Steps.Set_resolutionHeight_WindowsMobile(800);
            _Steps.Set_resolutionWidth_WindowsMobile(600);
            _Steps.Set_optional(true);
        end;

    end;

    local procedure GetReasonCode(): Text[20000]
    var
        L_ReasonCode: Record "Reason Code";
        ListOfReasonCode: Code[2048];
    begin
        L_ReasonCode.Reset();
        if L_ReasonCode.FindSet() then begin
            repeat
                ListOfReasonCode := ListOfReasonCode + ';' + L_ReasonCode.Code;
            until L_ReasonCode.Next() = 0;
        end;

        exit(ListOfReasonCode);

    end;

    //Unplanned Count++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnUnplannedCount_OnAfterCreateItemJnlLine', '', false, false)]
    local procedure OnPostAdhocRegistrationOnUnplannedCount_OnAfterCreateItemJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _ItemJnlLine: Record "Item Journal Line")
    var
        L_ResonCode: Code[20];
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        Clear(L_ResonCode);
        L_ResonCode := _RequestValues.GetValue('CustReasonCode');

        if L_ResonCode <> '' then begin
            _ItemJnlLine.Validate("Reason Code", L_ResonCode);
            // _ItemJnlLine.Modify();
        end;

    end;


    //adjust Qty++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateItemJnlLine', '', false, false)]
    local procedure OnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateItemJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _ItemJnlLine: Record "Item Journal Line")
    var
        L_ResonCode: Code[20];
        L_comments: Text[2048];
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
    begin
        Clear(L_ResonCode);
        Clear(L_comments);
        L_ResonCode := _RequestValues.GetValue('CustReasonCode');
        L_comments := _RequestValues.GetValue('Comments');

        if L_ResonCode <> '' then begin
            _ItemJnlLine.Validate("Reason Code", L_ResonCode);
            //_ItemJnlLine.Modify();
        end;

        if L_comments <> '' then
            _ItemJnlLine.Validate(Comments, L_comments);

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateWhseJnlLine', '', false, false)]
    local procedure OnPostAdhocRegistrationOnAdjustQuantity_OnAfterCreateWhseJnlLine(var _RequestValues: Record "MOB NS Request Element"; var _WhseJnlLine: Record "Warehouse Journal Line")
    var
        L_comments: Text[2048];
    begin
        L_comments := _RequestValues.GetValue('Comments');
        if L_comments <> '' then
            _WhseJnlLine.Comments := L_comments;
    end;


    [EventSubscriber(ObjectType::Codeunit, 22, 'OnAfterInitItemLedgEntry', '', false, false)]
    local procedure OnAfterInitItemLedgEntry(var ItemJournalLine: Record "Item Journal Line"; var NewItemLedgEntry: Record "Item Ledger Entry")
    begin
        if ItemJournalLine.Comments <> '' then
            NewItemLedgEntry.Comments := ItemJournalLine.Comments;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Jnl.-Register Line", 'OnInitWhseEntryCopyFromWhseJnlLine', '', false, false)]
    local procedure OnInitWhseEntryCopyFromWhseJnlLine(var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
        Clear(G_WarehouseEntryNo);
        G_WarehouseEntryNo := WarehouseEntry."Entry No.";
        if WarehouseJournalLine.Comments <> '' then
            WarehouseEntry.Comments := WarehouseJournalLine.Comments;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistration_OnAfterPost', '', false, false)]
    local procedure OnPostAdhocRegistration_OnAfterPost(_RegistrationType: Text; _MessageId: Guid; var _RequestValues: Record "MOB NS Request Element"; var _XmlResponseDoc: XmlDocument)
    var
        ImageIdsAndNotes: Text;
        RecRef: RecordRef;
        ReferenceID: RecordId;
        L_WarehouseEntry: Record "Warehouse Entry";
        MobWmsMediaQueue: Record "MOB WMS Media Queue";
        ImageList: List of [Text];
        ImageAndNoteList: List of [Text];
        MobDocQueue: Record "MOB Document Queue";

        // >> CHANGED BY TASKLET 
        MobSessionData: Codeunit "MOB SessionData";
        // << CHANGED BY TASKLET 

        ////Post+++
        Post_RecRef: RecordRef;
        MobBaseDocHandler: Codeunit "MOB WMS Base Document Handler";
        SourceRecRef: RecordRef;
        tes: Codeunit "MOB WMS Media";
        tess: Record "Tenant Media";
        Base64String: Text;
    begin
        Clear(ImageIdsAndNotes);
        Clear(Base64String);
        if _RegistrationType = 'AdjustQuantity' then begin
            ImageIdsAndNotes := _RequestValues.GetValue('ImageCapture', true);
            if ImageIdsAndNotes <> '' then begin
                if L_WarehouseEntry.Get(G_WarehouseEntryNo) then begin
                    ReferenceID := L_WarehouseEntry.RecordId;

                    // >> CHANGED BY TASKLET 
                    //if MobDocQueue.Get(_MessageId) then;
                    MobDocQueue.GetByGuid(MobSessionData.GetPostingMessageId(), MobDocQueue);
                    // << CHANGED BY TASKLET 

                    MobWmsMediaQueue.Init();
                    ImageList := ImageIdsAndNotes.Split('§');
                    foreach ImageIdsAndNotes in ImageList do begin
                        ImageAndNoteList := ImageIdsAndNotes.Split(';');
                        ImageAndNoteList.Get(1, MobWmsMediaQueue."Image Id");
                        ImageAndNoteList.Get(2, MobWmsMediaQueue.Note);
                        MobWmsMediaQueue."Device ID" := MobDocQueue."Device ID";
                        MobWmsMediaQueue."Record ID" := ReferenceID;
                        MobWmsMediaQueue.Description := Format(MobWmsMediaQueue."Record ID");
                        MobWmsMediaQueue.Insert(true);
                        //if MobWmsMediaQueue.Insert(true) then begin
                        // //Post++
                        // GetMediaIdAsBase64String(MobWmsMediaQueue.Picture.MediaId(), Base64String);

                        // StreamBase64DataToMobWmsMediaQueue(MobWmsMediaQueue, Base64String);
                        // MobWmsMediaQueue.Modify(true);

                        // // Get the Record the Image should be attached to
                        // Post_RecRef.Get(MobWmsMediaQueue."Record ID");

                        // // Find the source doc from ReferenceID
                        // if MobBaseDocHandler.GetSourceDocOrLine(RecRef, SourceRecRef) then
                        //     // Attach image to source document
                        //     MediaGuid := SaveAttachmentFromBase64(SourceRecRef, Data, MobWmsMediaQueue."Image Id");

                        //Error('In');
                        //end;
                    end;
                end;
            end;
        end;
    end;


    // local procedure GetMediaIdAsBase64String(_MediaId: Text; var _Base64String: Text)
    // var
    //     TenantMediaSet: Record "Tenant Media Set";
    //     TenantMedia: Record "Tenant Media";
    //     MobCommonMgt: Codeunit "MOB Common Mgt.";
    //     ImageStream: InStream;
    //     MediaGuid: Guid;
    // begin
    //     TenantMediaSet.SetRange("Company Name", CompanyName());
    //     TenantMediaSet.SetRange(ID, _MediaId);
    //     if not TenantMediaSet.FindFirst() then
    //         exit;

    //     // Select the Image
    //     MediaGuid := SelectStr(1, Format(TenantMediaSet."Media ID"));

    //     // Get media
    //     TenantMedia.SetRange("Company Name", CompanyName());
    //     TenantMedia.SetRange(ID, MediaGuid);
    //     TenantMedia.SetAutoCalcFields(Content);
    //     if not TenantMedia.FindFirst() then
    //         exit;

    //     // Convert to Stream
    //     TenantMedia.Content.CreateInStream(ImageStream);

    //     // Convert to Base64
    //     MobCommonMgt.ConvertStreamToBase64String(ImageStream, _Base64String);
    // end;

    // local procedure StreamBase64DataToMobWmsMediaQueue(var _MobWmsMediaQueue: Record "MOB WMS Media Queue"; _Base64Data: Text)
    // var
    //     MobCommonMgt: Codeunit "MOB Common Mgt.";
    //     ImageInStream: InStream;
    // begin
    //     MobCommonMgt.CreateInStreamFromBase64(ImageInStream, _Base64Data);
    //     _MobWmsMediaQueue.Picture.ImportStream(ImageInStream, _MobWmsMediaQueue.Note);
    // end;


}