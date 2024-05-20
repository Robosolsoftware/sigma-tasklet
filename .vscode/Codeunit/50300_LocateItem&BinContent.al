codeunit 50300 LocateItemANDBinContent
{
    trigger OnRun()
    begin

    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', false, false)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    var
    begin
        //Locate Item++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        _HeaderFields.InitConfigurationKey('LocateItemHeader');
        _HeaderFields.Create_ListField_FilterLocationAsLocation(10);
        _HeaderFields.Create_TextField_ItemNumber(20);
        _HeaderFields.Create_TextField_LotNumber(21);
        _HeaderFields.Set_optional(true);
        //LocateItem----------------------------------------------------------


        //Bin Content++++++++++++++++++++++++++++++
        // Identifier for new ConfigurationKey - replace by your own key name
        _HeaderFields.InitConfigurationKey('BinContentHeaderNew');

        // Add the header lines
        _HeaderFields.Create_ListField_Location(10);
        _HeaderFields.Create_TextField_Bin(20);
        _HeaderFields.Create_TextField_LotNumber(21);
        _HeaderFields.Set_optional(true);
        //Bin Content--------------------------------

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Lookup", 'OnLookupOnCustomLookupType', '', true, true)]
    local procedure MyOnLookupOnCustomLookupType(_MessageId: Guid; _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _XmlResultDoc: XmlDocument; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
        if (_LookupType <> 'LocateItemNew') AND (_LookupType <> 'BinContentNew') then
            exit;

        case _LookupType of
            'LocateItemNew':
                begin
                    LookUpLocateItem(_LookupType, _RequestValues, _RegistrationTypeTracking, _XmlResultDoc);
                    _IsHandled := true;

                end;
            'BinContentNew':
                begin
                    LookupBinContent(_LookupType, _RequestValues, _LookupResponseElement, _RegistrationTypeTracking, _XmlResultDoc);
                    _IsHandled := true;
                end;

        end;
    end;

    local procedure LookUpLocateItem(var L_LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; _ReturnRegistrationTypeTracking: Text; var _XmlResultDoc: XmlDocument)
    var
        ItemNumber: Code[50];
        ScannedItemNumber: Text;
        LocationCode: Text[10];
        VariantCode: Code[10];
        lotno: Code[20];
        Location: Record Location;
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobDocQueue: Record "MOB Document Queue";
        BinContent: Record "Bin Content";
        Item: Record Item;
        RegisterSerialNo: Boolean;
        RegisterLotNo: Boolean;
        RegisterExpirationDate: Boolean;
        TempEntrySummary: Record "Entry Summary" temporary;
        BinContentLotSerial: Record "Bin Content";
        BinContentIsIncluded: Boolean;
        TempLookupResponseElement: Record "MOB NS WhseInquery Element" temporary;
        XmlResponseData: XmlNode;
        ItemVariant: Record "Item Variant";
        MobXmlMgt: Codeunit "MOB Xml Management";
        MobWmsLookup: Codeunit "MOB WMS Lookup";
        ExpiryDate: Date;
        Check_Location: Code[20];
        MobSessionData: Codeunit "MOB SessionData";
    begin
        ScannedItemNumber := _RequestValues.GetValue('ItemNumber', true);
        ItemNumber := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(ScannedItemNumber), VariantCode);
        LocationCode := _RequestValues.GetValue('Location', true);
        lotno := _RequestValues.Get_LotNumber();



        _ReturnRegistrationTypeTracking := DelChr(LocationCode + ' - ' + ItemNumber + ' - ' + VariantCode, '<>', ' - ');

        MobToolbox.InitializeResponseDocWithNS(_XmlResultDoc, XmlResponseData, MobXmlMgt.NS_WHSEMODEL());

        // Only search the locations this user has been assigned
        MobDocQueue.GetByGuid(MobSessionData.GetPostingMessageId(), MobDocQueue);

        if LocationCode = 'All' then
            Location.SetFilter(Code, MobWmsToolbox.GetLocationFilter(MobDocQueue."Mobile User ID"))
        else
            Location.SetRange(Code, LocationCode);

        if Location.FindSet() then
            repeat
                if Location."Bin Mandatory" then begin
                    BinContent.SetCurrentKey("Item No.");
                    BinContent.SetFilter("Item No.", ItemNumber);  // Support wildcard search
                    if VariantCode <> '' then
                        BinContent.SetRange("Variant Code", VariantCode);
                    BinContent.SetFilter("Location Code", Location.Code);
                    BinContent.SetFilter(Quantity, '>0');
                    //BinContent.SetRange("Lot No. Filter", lotno);
                    if BinContent.FindSet() then begin
                        repeat
                            Item.Reset();
                            Item.Get(BinContent."Item No.");

                            MobWmsToolbox.WsheTrackingEnabledExpDate(BinContent."Item No.", RegisterSerialNo, RegisterLotNo, RegisterExpirationDate);

                            if RegisterSerialNo or RegisterLotNo then begin


                                MobWmsToolbox.GetTrackedSummary(TempEntrySummary, Location, BinContent."Bin Code", BinContent."Item No.", BinContent."Variant Code", BinContent."Unit of Measure Code", RegisterExpirationDate);




                                if lotno <> '' then begin
                                    TempEntrySummary.SetRange("Lot No.", lotno);
                                end else begin
                                    // Respect additional filters from event
                                    BinContent.CopyFilter("Serial No. Filter", TempEntrySummary."Serial No.");
                                    BinContent.CopyFilter("Lot No. Filter", TempEntrySummary."Lot No.");
                                end;


                                //end;
                                if TempEntrySummary.FindSet() then
                                    repeat


                                        BinContentLotSerial.Reset();
                                        BinContentLotSerial.CopyFilters(BinContent);
                                        BinContentLotSerial.SetRange("Location Code", Location.Code);
                                        BinContentLotSerial.SetRange("Bin Code", BinContent."Bin Code");
                                        BinContentLotSerial.SetRange("Item No.", BinContent."Item No.");
                                        BinContentLotSerial.SetRange("Variant Code", BinContent."Variant Code");
                                        BinContentLotSerial.SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
                                        BinContentLotSerial.SetRange("Serial No. Filter", TempEntrySummary."Serial No.");
                                        BinContentLotSerial.SetRange("Lot No. Filter", TempEntrySummary."Lot No.");
                                        BinContentLotSerial.SetFilter(Quantity, '>0');
                                        if BinContentLotSerial.FindFirst() then begin
                                            BinContentLotSerial.CalcFields(Quantity, "Pick Qty.", "Neg. Adjmt. Qty.");
                                            BinContentIsIncluded := true;
                                            if BinContentIsIncluded then begin
                                                // Determine if the item uses serial or lot tracking
                                                // Yes -> find the tracking information
                                                // No  -> just use the quantity from the bin content table

                                                // Populate LookupResponse buffer element for <LookupResponse> (Bin Content with RegisterSerialNo or RegisterLotNo)
                                                TempLookupResponseElement.Create();
                                                SetFromLookupLocateItem_BinContent(
                                                    Location,
                                                    BinContentLotSerial,
                                                    TempEntrySummary."Serial No.",
                                                    TempEntrySummary."Lot No.",
                                                    TempEntrySummary."Expiration Date",
                                                    TempLookupResponseElement);
                                                TempLookupResponseElement.Save();
                                            end;
                                        end;


                                    until TempEntrySummary.Next() = 0;


                            end else begin
                                BinContent.CalcFields(Quantity, "Pick Qty.", "Neg. Adjmt. Qty.");

                                BinContentIsIncluded := true;
                                if BinContentIsIncluded then begin
                                    // Populate LookupResponse buffer element for <LookupResponse> (Bin Content with no RegisterSerialNo or RegisterLotNo)
                                    TempLookupResponseElement.Create();
                                    SetFromLookupLocateItem_BinContent(
                                        Location,
                                        BinContent,
                                        '',     // SerialNumber
                                        '',     // LotNumber
                                        0D,     // ExpirationDate                                        
                                        TempLookupResponseElement);
                                    TempLookupResponseElement.Save();
                                end;
                            end;



                        until BinContent.Next() = 0;
                    end;


                end else begin
                    Item.Get(ItemNumber);
                    Item.SetRange("Location Filter", Location.Code);
                    ItemVariant.SetRange("Item No.", Item."No.");
                    if VariantCode <> '' then
                        ItemVariant.SetRange(Code, VariantCode);

                    // Add inventory (Item has variants)
                    if ItemVariant.FindSet() then
                        repeat
                            AddLookupLocateItemElement(Item, Location, ItemVariant, TempLookupResponseElement);
                        until ItemVariant.Next() = 0;

                    // Include 'blank' variant inventory
                    if VariantCode = '' then begin
                        Clear(ItemVariant);
                        AddLookupLocateItemElement(Item, Location, ItemVariant, TempLookupResponseElement);
                    end;


                end;

            until Location.Next() = 0;

        MobWmsLookup.AddLookupResponseElements(L_LookupType, XmlResponseData, TempLookupResponseElement);
    end;

    local procedure SetFromLookupLocateItem_BinContent(_Location: Record "Location";
_BinContent: Record "Bin Content";
_SerialNumber: Code[50];
_LotNumber: Code[50];
_ExpirationDate: Date; var
                   _LookupResponseElement: Record "MOB NS WhseInquery Element")
    var
        MobWmsMedia: Codeunit "MOB WMS Media";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        DisplayLine2List: List of [Text];
        L_Item: Record Item;
        test: Text;
        test1: Text;
    begin

        Clear(test);
        Clear(test1);
        L_Item.Reset();
        L_Item.Get(_BinContent."Item No.");

        _LookupResponseElement.Init();

        _LookupResponseElement.Set_Location(_BinContent."Location Code");
        _LookupResponseElement.Set_ItemNumber(_BinContent."Item No.");
        _LookupResponseElement.Set_Variant(_BinContent."Variant Code");
        _LookupResponseElement.Set_Barcode('');

        _LookupResponseElement.Set_SerialNumber(_SerialNumber);
        _LookupResponseElement.Set_LotNumber(_LotNumber);
        _LookupResponseElement.Set_ExpirationDate(Format(_ExpirationDate));
        _LookupResponseElement.Set_DisplaySerialNumber(_SerialNumber <> '', MobWmsLanguage.GetMessage('SERIAL_NO_LABEL') + ': ' + _SerialNumber, '');
        test := StrSubstNo('%1 %2 %3%4', MobWmsLanguage.GetMessage('LOT_NO_LABEL'), ':', _LotNumber, MobToolbox.CRLFSeparator());
        test1 := StrSubstNo('%1%2 %3 %4', test, 'Exp.Date', ': ', MobWmsToolbox.Date2TextAsDisplayFormat(_ExpirationDate));
        // _LookupResponseElement.Set_DisplayLotNumber(_LotNumber <> '', test, ''+MobWmsLanguage.GetMessage('EXP_DATE_LABEL'));
        // _LookupResponseElement.Set_DisplayExpirationDate(_ExpirationDate <> 0D, test1, '');


        _LookupResponseElement.Set_Bin(_BinContent."Bin Code");
        _LookupResponseElement.Set_Quantity(_BinContent.Quantity - _BinContent."Pick Qty." - _BinContent."Neg. Adjmt. Qty.");  // Available Quantity
        _LookupResponseElement.Set_UoM(_BinContent."Unit of Measure Code");

        _LookupResponseElement.Set_DisplayLine1(_BinContent."Item No.");
        _LookupResponseElement.Set_DisplayLine2(L_Item.Description);
        //_LookupResponseElement.Set_DisplayLine3(MobWmsLanguage.GetMessage('BIN') + ': ' + _BinContent."Bin Code");
        _LookupResponseElement.Set_DisplayLine3(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _BinContent."Unit of Measure Code");
        _LookupResponseElement.Set_DisplayLine4(_BinContent."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _BinContent."Variant Code", '' + MobToolbox.CRLFSeparator() + test1 + MobToolbox.CRLFSeparator() + MobWmsLanguage.GetMessage('BIN') + ':' + _BinContent."Bin Code");
        //_LookupResponseElement.Set_DisplayLine5(test1);
        //_LookupResponseElement.Set_DisplayLine5(_BinContent."Bin Code");
        _LookupResponseElement.Set_ExtraInfo1(Format(_BinContent.Quantity, 0, 9));
        _LookupResponseElement.Set_ExtraInfo2('');
        _LookupResponseElement.Set_ExtraInfo3('');


        _LookupResponseElement.Set_ItemImageID(MobWmsMedia.GetItemImageID(_LookupResponseElement.Get_ItemNumber()));

    end;

    local procedure AddLookupLocateItemElement(var _Item: Record Item; _Location: Record Location; _ItemVariant: Record "Item Variant"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        ItemIsIncluded: Boolean;
    begin
        _Item.SetRange("Variant Filter", _ItemVariant.Code);
        _Item.CalcFields(Inventory, "Qty. on Sales Order", "Trans. Ord. Shipment (Qty.)", "Qty. on Service Order");
        MobCommonMgt.Item_CalcFields_QtyOnComponentines(_Item); // wrapper for "Scheduled Need (Qty.)" (BC 17 or earlier) or "Qty. on Component Lines" (BC18 and newer)

        ItemIsIncluded := _Item.Inventory > 0;
        //OnLookupOnLocateItem_OnIncludeItem(_Location, _Item, _ItemVariant, ItemIsIncluded);

        if ItemIsIncluded then begin
            _LookupResponse.Create();
            SetFromLookupLocateItem_Item(_Location, _Item, _ItemVariant, _LookupResponse);
            _LookupResponse.Save();
        end;
    end;

    local procedure SetFromLookupLocateItem_Item(_Location: Record "Location"; _Item: Record Item; _ItemVariant: Record "Item Variant"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    var
        MobWmsMedia: Codeunit "MOB WMS Media";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        AvailableQuantity: Decimal;
    begin
        // Calculate AvailableQuantity : assume flowfields has been calculated already including correct filters

        // Item
        AvailableQuantity := _Item.Inventory - _Item."Qty. on Sales Order" - _Item."Qty. on Component Lines" - _Item."Trans. Ord. Shipment (Qty.)" - _Item."Qty. on Service Order";  //Replaced "Scheduled Need (Qty.)" with "Qty. on Component Lines" //Robosol++

        _LookupResponseElement.Init();

        _LookupResponseElement.Set_Location(_Location.Code);
        _LookupResponseElement.Set_ItemNumber(_Item."No.");
        _LookupResponseElement.Set_Variant(_ItemVariant.Code);
        _LookupResponseElement.Set_Barcode('');
        _LookupResponseElement.Set_SerialNumber('');
        _LookupResponseElement.Set_LotNumber('');
        _LookupResponseElement.Set_Bin('');
        _LookupResponseElement.Set_Quantity(AvailableQuantity);
        _LookupResponseElement.Set_UoM(_Item."Base Unit of Measure");

        _LookupResponseElement.Set_DisplayLine1(_Location.Name <> '', _Location.Name, _Location.Code);
        _LookupResponseElement.Set_DisplayLine2('');
        _LookupResponseElement.Set_DisplayLine3(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _Item."Base Unit of Measure");
        _LookupResponseElement.Set_DisplayLine4(_ItemVariant.Code <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _ItemVariant.Code, '');
        _LookupResponseElement.Set_DisplayLine5('');

        _LookupResponseElement.Set_ExtraInfo1(Format(_Item.Inventory, 0, 9));
        _LookupResponseElement.Set_ExtraInfo2('');
        _LookupResponseElement.Set_ExtraInfo3('');

        _LookupResponseElement.Set_ItemImageID(MobWmsMedia.GetItemImageID(_LookupResponseElement.Get_ItemNumber()));

        //OnLookupOnLocateItem_OnAfterSetFromItem(_Location, _Item, _ItemVariant, _LookupResponseElement);
    end;

    local procedure LookupBinContent(_LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponse: Record "MOB NS WhseInquery Element"; var _ReturnRegistrationTypeTracking: Text; _XmlResultDoc: XmlDocument)
    var
        Location: Record Location;
        BinContent: Record "Bin Content";
        BinContentLotSerial: Record "Bin Content";
        TempEntrySummary: Record "Entry Summary" temporary;
        LocationCode: Code[10];
        ScannedBin: Text;
        BinCode: Code[20];
        SNRequired: Boolean;
        LotRequired: Boolean;
        ExpDateRequired: Boolean;
        BinContentIsIncluded: Boolean;
        EntrySummaryFound: Boolean;
        TrackingRequired: Boolean;
        lotno: Code[20];
        XmlResponseData: XmlNode;
        MobXmlMgt: Codeunit "MOB Xml Management";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        LocationCode := _RequestValues.GetValue('Location', true);
        ScannedBin := _RequestValues.GetValue('Bin', true);
        BinCode := MobToolbox.ReadBin(ScannedBin);
        lotno := _RequestValues.Get_LotNumber();
        Location.Get(LocationCode);

        _ReturnRegistrationTypeTracking := DelChr(LocationCode + ' - ' + BinCode, '<>', ' - ');

        MobToolbox.InitializeResponseDocWithNS(_XmlResultDoc, XmlResponseData, MobXmlMgt.NS_WHSEMODEL());

        BinContent.SetCurrentKey("Location Code", "Bin Code");
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetFilter(Quantity, '<>0');
        if BinContent.FindSet() then
            repeat
                MobWmsToolbox.WsheTrackingEnabledExpDate(BinContent."Item No.", SNRequired, LotRequired, ExpDateRequired);

                EntrySummaryFound := false;
                TrackingRequired := SNRequired or LotRequired;

                if TrackingRequired then begin
                    // Item is tracked, get at summary to Look Up in Bin Content
                    MobWmsToolbox.GetTrackedSummary(TempEntrySummary, Location, BinContent."Bin Code", BinContent."Item No.", BinContent."Variant Code", BinContent."Unit of Measure Code", ExpDateRequired);

                    if lotno <> '' then begin
                        TempEntrySummary.SetRange("Lot No.", lotno);
                    end else begin
                        // Respect additional filters from event
                        BinContent.CopyFilter("Serial No. Filter", TempEntrySummary."Serial No.");
                        BinContent.CopyFilter("Lot No. Filter", TempEntrySummary."Lot No.");
                    end;



                    if TempEntrySummary.FindSet() then begin
                        EntrySummaryFound := true;
                        repeat
                            BinContentLotSerial.Reset();
                            BinContentLotSerial.CopyFilters(BinContent);    // Respect Quantity filter and additional filters from event
                            BinContentLotSerial.SetRange("Location Code", Location.Code);
                            BinContentLotSerial.SetRange("Bin Code", BinContent."Bin Code");
                            BinContentLotSerial.SetRange("Item No.", BinContent."Item No.");
                            BinContentLotSerial.SetRange("Variant Code", BinContent."Variant Code");
                            BinContentLotSerial.SetRange("Unit of Measure Code", BinContent."Unit of Measure Code");
                            BinContentLotSerial.SetRange("Serial No. Filter", TempEntrySummary."Serial No.");
                            BinContentLotSerial.SetRange("Lot No. Filter", TempEntrySummary."Lot No.");

                            if BinContentLotSerial.FindFirst() then begin
                                // Recalculate in case Quantity-filter was entirely removed from event
                                BinContentLotSerial.CalcFields(Quantity);

                                // Populate LookupReponse buffer element for <LookupResponse>
                                BinContentIsIncluded := true;
                                //OnLookupOnBinContent_OnIncludeBinContent(BinContentLotSerial, BinContentIsIncluded);
                                if BinContentIsIncluded then begin
                                    _LookupResponse.Create();
                                    SetFromLookupBinContent(
                                        BinContentLotSerial,
                                        TempEntrySummary."Serial No.",
                                        TempEntrySummary."Lot No.",
                                        TempEntrySummary."Expiration Date",
                                        _LookupResponse);
                                    _LookupResponse.Save();
                                end;
                            end;
                        until TempEntrySummary.Next() = 0;
                    end;    // EntrySummary found
                end;
                if not (TrackingRequired and EntrySummaryFound) then begin
                    // Fallback for no tracking and tracked items with no inventory on hand

                    // Recalculate in case Quantity-filter was entirely removed from event
                    BinContent.CalcFields(Quantity);

                    // Populate LookupReponse buffer element for <LookupResponse>
                    BinContentIsIncluded := true;
                    //OnLookupOnBinContent_OnIncludeBinContent(BinContent, BinContentIsIncluded);
                    if BinContentIsIncluded then begin
                        _LookupResponse.Create();
                        SetFromLookupBinContent(
                            BinContent,
                            '',     // Serial Number
                            '',     // Lot Number
                            0D,     // Expiration Date
                            _LookupResponse);
                        _LookupResponse.Save();
                    end;
                end;
            until BinContent.Next() = 0;
    end;

    local procedure SetFromLookupBinContent(_BinContent: Record "Bin Content"; _SerialNumber: Code[50]; _LotNumber: Code[50]; _ExpirationDate: Date; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsMedia: Codeunit "MOB WMS Media";
        LineBuf: array[10] of Text[250];
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        LOTtext: Text;
        ExpText: Text;
    begin
        Clear(LOTtext);
        Clear(ExpText);
        Item.Get(_BinContent."Item No.");

        // Populate LineBuf[1] and LineBuf[2] from details about the BinContent
        Clear(LineBuf);
        if (_BinContent."Variant Code" <> '') and (ItemVariant.Get(_BinContent."Item No.", _BinContent."Variant Code")) then
            GetText(ItemVariant.Description, ItemVariant."Description 2", LineBuf)
        else
            GetText(Item.Description, Item."Description 2", LineBuf);

        _LookupResponse.Init();

        _LookupResponse.Set_Location(_BinContent."Location Code");
        _LookupResponse.Set_ItemNumber(_BinContent."Item No.");
        _LookupResponse.Set_Variant(_BinContent."Variant Code");
        _LookupResponse.Set_Barcode('');

        _LookupResponse.Set_SerialNumber(_SerialNumber);
        _LookupResponse.Set_LotNumber(_LotNumber);
        _LookupResponse.Set_ExpirationDate(_ExpirationDate);
        _LookupResponse.Set_DisplaySerialNumber(_SerialNumber <> '', MobWmsLanguage.GetMessage('SERIAL_NO_LABEL') + ': ' + _SerialNumber, '');
        LOTtext := StrSubstNo('%1 %2 %3%4', MobWmsLanguage.GetMessage('LOT_NO_LABEL'), ':', _LotNumber, MobToolbox.CRLFSeparator());
        ExpText := StrSubstNo('%1%2 %3 %4', LOTtext, MobWmsLanguage.GetMessage('EXP_DATE_LABEL'), ': ', MobWmsToolbox.Date2TextAsDisplayFormat(_ExpirationDate));
        //_LookupResponse.Set_DisplayLotNumber(_LotNumber <> '', MobWmsLanguage.GetMessage('LOT_NO_LABEL') + ': ' + _LotNumber, '');
        //_LookupResponse.Set_DisplayExpirationDate(_ExpirationDate <> 0D, MobWmsLanguage.GetMessage('EXP_DATE_LABEL') + ': ' + MobWmsToolbox.Date2TextAsDisplayFormat(_ExpirationDate), '');

        _LookupResponse.Set_Bin(_BinContent."Bin Code");
        _LookupResponse.Set_Quantity(_BinContent.Quantity);
        _LookupResponse.Set_UoM(_BinContent."Unit of Measure Code");

        _LookupResponse.Set_DisplayLine1(_BinContent."Item No.");
        _LookupResponse.Set_DisplayLine2(LineBuf[1]);
        _LookupResponse.Set_DisplayLine3(_BinContent."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _BinContent."Variant Code", LineBuf[2]);
        _LookupResponse.Set_DisplayLine4(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _BinContent."Unit of Measure Code" + MobToolbox.CRLFSeparator() + ExpText);
        _LookupResponse.Set_DisplayLine5('');

        _LookupResponse.Set_ExtraInfo1('');
        _LookupResponse.Set_ExtraInfo2('');
        _LookupResponse.Set_ExtraInfo3('');

        _LookupResponse.Set_ItemImageID(MobWmsMedia.GetItemImageID(_LookupResponse.Get_ItemNumber()));
        _LookupResponse.Set_ReferenceID(_BinContent);

        //OnLookupOnBinContent_OnAfterSetFromBinContent(_BinContent, _LookupResponse);
    end;

    procedure GetText(_InputText1: Text[250]; _InputText2: Text[250]; var _LineBuf: array[10] of Text[250]): Integer
    begin
        if (StrLen(_InputText1) <= 35) and (StrLen(_InputText2) <= 35) then begin
            _LineBuf[1] := _InputText1;
            _LineBuf[2] := _InputText2;
        end else
            SplitText(_InputText1 + ' ' + _InputText2, _LineBuf);
    end;

    local procedure SplitText(InputText: Text[250]; var _LineBuf: array[10] of Text[250]): Integer;
    var
        i: Integer;
        RemainingText: Text[250];
        NextWord: Text[250];
        WordLen: Integer;
        LineLength: Integer;
        InputLine: Integer;
        test: Record 5767;
    begin
        Clear(_LineBuf);
        InputLine := 1;
        LineLength := 0;
        RemainingText := InputText;

        repeat
            i := STRPOS(RemainingText, ' ');
            if i = 0 then begin
                NextWord := RemainingText;
                RemainingText := '';
            end else begin
                NextWord := CopyStr(RemainingText, 1, i - 1);
                RemainingText := CopyStr(RemainingText, i + 1);
            end;
            WordLen := StrLen(NextWord);

            if (LineLength + WordLen <= 35) then begin
                _LineBuf[InputLine] += NextWord;
                LineLength += WordLen;
                if LineLength < 35 then begin
                    _LineBuf[InputLine] += ' ';
                    LineLength += 1;
                end
            end else
                if WordLen <= 35 then begin
                    InputLine += 1;
                    _LineBuf[InputLine] := NextWord;
                    LineLength := WordLen;
                    if LineLength < 35 then begin
                        _LineBuf[InputLine] += ' ';
                        LineLength += 1;
                    end
                end;

        until RemainingText = '';
        exit(InputLine);
    end;


    var
        myInt: Integer;
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobToolbox: Codeunit "MOB Toolbox";
}