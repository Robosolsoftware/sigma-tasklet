codeunit 50311 "Polar Speed Changes"
{
    Permissions = tabledata 110 = m;
    trigger OnRun()
    begin

    end;

    var
        myInt: Integer;

    #Region For KNAPP PS Label++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Report Print Lookup", 'OnLookupOnPrintReport_OnAddStepsForReport', '', true, true)]
    local procedure OnLookupOnPrintReport_OnAddStepsForKnappLabel(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element"; var _IsHandled: Boolean)
    var
        MobReportPrintSteps: Codeunit "MOB Report Print Lookup";
    begin
        if _MobReport."RequestPage Handler" = _MobReport."RequestPage Handler"::"PolarSpeed Label1" then begin

            _Steps.Create_TextStep(10, 'ToteNo');
            _Steps.Set_header('Tote No');
            _Steps.Set_label('Tote No:');

            _Steps.Create_IntegerStep(20, 'ToteSeq');
            _Steps.Set_header('Tote Sequence');
            _Steps.Set_label('Enter Tote Sequence:');
            _Steps.Set_defaultValue(0);
            _Steps.Set_minValue(1);
            _Steps.Set_maxValue(99);
            _Steps.Set_length(99);


            MobReportPrintSteps.CreateReportPrinterAndNoOfCopiesSteps(_MobReport, _RequestValues, _Steps, 90, 0);
            _IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB ReportParameters Mgt.", 'OnCreateReportParameters', '', true, true)]
    local procedure OnCreateReportParametersKnappLabel(_MobReport: Record "Mob Report"; _SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element" temporary; var _OptionsFieldValues: Record "MOB ReportParameters Element"; var _DataItemViews: Record "MOB ReportParameters Element"; var _IsHandled: Boolean)
    var
        L_PolarSpeedBarcodeDetails: Record "Polar Speed Barcode Details";
        KnappOrdResponse: Record "Knapp Order Response";
        SalesHeader: Record "Sales Header";
        NoSeriesMgt: Codeunit "No. Series";
        L_SalesInvoiceHeader: Record "Sales Invoice Header";
        OrderNoFilter: Code[2000];
        DuplicateOrderNo: Code[2000];
        L_SalesLine: Record "Sales Line";
        L_Item: Record Item;
        L_SalesInvoiceLine: Record "Sales Invoice Line";
        L_IUM: Record "Item Unit of Measure";
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::"PolarSpeed Label1" then
            exit;

        #Region Check Tote sequence is already available for scanned tote and same day+++
        Clear(OrderNoFilter);
        Clear(DuplicateOrderNo);
        KnappOrdResponse.Reset();
        KnappOrdResponse.SetRange("Document Type", KnappOrdResponse."Document Type"::Order);
        KnappOrdResponse.SetRange("Load Unit", _RequestValues.GetValue('ToteNo'));
        KnappOrdResponse.SetFilter(Quantity, '>%1', 0);
        KnappOrdResponse.SetRange("PS Label Exist", false);
        KnappOrdResponse.SetFilter(SystemCreatedAt, '%1..%2', CreateDateTime(WorkDate(), 000000T), CreateDateTime(WorkDate(), 235959T));
        if KnappOrdResponse.FindSet() then begin
            repeat
                if OrderNoFilter <> '' then begin
                    if DuplicateOrderNo <> KnappOrdResponse."Document No." then begin
                        OrderNoFilter := '|' + KnappOrdResponse."Document No.";
                        DuplicateOrderNo := KnappOrdResponse."Document No.";
                    end;
                end else begin
                    OrderNoFilter := KnappOrdResponse."Document No.";
                    DuplicateOrderNo := KnappOrdResponse."Document No.";
                end;
            until KnappOrdResponse.Next() = 0;
            if OrderNoFilter = '' then
                Error('This label has already been printed/No label to print. Contact supervisor.');


            //Check Duplicat Tote sequence+++
            L_PolarSpeedBarcodeDetails.Reset();
            L_PolarSpeedBarcodeDetails.SetFilter("Order No.", OrderNoFilter);
            L_PolarSpeedBarcodeDetails.SetRange("No. of Box / Tote Sequence", _RequestValues.GetValueAsInteger('ToteSeq'));
            L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
            if L_PolarSpeedBarcodeDetails.FindSet() then
                repeat
                    if L_PolarSpeedBarcodeDetails."Tote/Order No." <> _RequestValues.GetValue('ToteNo') then
                        Error('The tote sequence %1 already exists for tote %2', L_PolarSpeedBarcodeDetails."No. of Box / Tote Sequence", L_PolarSpeedBarcodeDetails."Tote/Order No.");
                until L_PolarSpeedBarcodeDetails.Next() = 0;
        end;
        #EndRegion Check Tote sequence is already available for scanned tote and same day+++


        //Create PS label Details & Print the label+++ 
        Clear(DuplicateOrderNo);
        KnappOrdResponse.Reset();
        KnappOrdResponse.SetRange("Document Type", KnappOrdResponse."Document Type"::Order);
        KnappOrdResponse.SetRange("Load Unit", _RequestValues.GetValue('ToteNo'));
        KnappOrdResponse.SetFilter(Quantity, '>%1', 0);
        KnappOrdResponse.SetRange("PS Label Exist", false);
        KnappOrdResponse.SetFilter(SystemCreatedAt, '%1..%2', CreateDateTime(WorkDate(), 000000T), CreateDateTime(WorkDate(), 235959T));
        KnappOrdResponse.SetCurrentKey("Document No.");
        KnappOrdResponse.Ascending(true);
        if KnappOrdResponse.FindSet() then begin
            repeat
                if DuplicateOrderNo <> KnappOrdResponse."Document No." then begin
                    L_PolarSpeedBarcodeDetails.Reset();
                    L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", KnappOrdResponse."Load Unit");
                    L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                    L_PolarSpeedBarcodeDetails.SetRange("Order No.", KnappOrdResponse."Document No.");
                    if not L_PolarSpeedBarcodeDetails.FindFirst() then begin
                        SalesHeader.Reset();
                        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                        SalesHeader.SetRange("No.", KnappOrdResponse."Document No.");
                        if SalesHeader.FindFirst() then begin
                            L_PolarSpeedBarcodeDetails.Init();
                            L_PolarSpeedBarcodeDetails."Entry No." := getlastentryno();
                            L_PolarSpeedBarcodeDetails."Tote/Order No." := _RequestValues.GetValue('ToteNo');
                            L_PolarSpeedBarcodeDetails."No. of Box / Tote Sequence" := _RequestValues.GetValueAsInteger('ToteSeq');
                            L_PolarSpeedBarcodeDetails."Order Category" := L_PolarSpeedBarcodeDetails."Order Category"::Knapp;
                            L_PolarSpeedBarcodeDetails."Customer No." := SalesHeader."Sell-to Customer No.";
                            L_PolarSpeedBarcodeDetails."Order No." := SalesHeader."No.";

                            //NOTE - In sigma, One order have only one shipment and Invoice for KNAPP orders++
                            L_SalesInvoiceHeader.Reset();
                            L_SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
                            if L_SalesInvoiceHeader.FindFirst() then begin
                                L_PolarSpeedBarcodeDetails."Sales Invoice No." := L_SalesInvoiceHeader."No.";
                            end else
                                L_PolarSpeedBarcodeDetails."Sales Invoice No." := SalesHeader."Posting No.";

                            L_PolarSpeedBarcodeDetails."Print Date" := WorkDate();
                            L_PolarSpeedBarcodeDetails."Shipment Date" := SalesHeader."Shipment Date";
                            L_PolarSpeedBarcodeDetails."Barcode No." := NoSeriesMgt.GetNextNo('PSLABEL', WorkDate(), true);

                            //Get Temprature And Storage++
                            L_SalesLine.Reset();
                            L_SalesLine.SetRange("No.", KnappOrdResponse."Item No.");
                            L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                            L_SalesLine.SetRange("Document No.", KnappOrdResponse."Document No.");
                            L_SalesLine.SetRange("Line No.", KnappOrdResponse."Line No.");
                            if L_SalesLine.FindFirst() then begin
                                if L_Item.Get(L_SalesLine."No.") then begin
                                    if L_Item.Storage = '2-8' then begin
                                        L_PolarSpeedBarcodeDetails.Storage := '2-8';
                                    end else begin
                                        L_PolarSpeedBarcodeDetails.Storage := '2-25';
                                    end;

                                    L_IUM.Reset();
                                    L_IUM.SetFilter(Code, L_Item."Base Unit of Measure");
                                    if L_IUM.FindFirst() then begin
                                        L_PolarSpeedBarcodeDetails.Weight := L_IUM.Weight;
                                    end;
                                end;
                            end else begin
                                //NOTE - In sigma, One order have only one shipment and Invoice for KNAPP orders++
                                L_SalesInvoiceLine.Reset();
                                L_SalesInvoiceLine.SetRange("Order No.", KnappOrdResponse."Document No.");
                                L_SalesInvoiceLine.SetRange("Line No.", KnappOrdResponse."Line No.");
                                L_SalesInvoiceLine.SetRange(Type, L_SalesInvoiceLine.Type::Item);
                                L_SalesInvoiceLine.SetFilter(Quantity, '>%1', 0);
                                if L_SalesInvoiceLine.FindFirst() then begin
                                    if L_Item.Get(L_SalesInvoiceLine."No.") then begin
                                        if L_Item.Storage = '2-8' then begin
                                            L_PolarSpeedBarcodeDetails.Storage := '2-8';
                                        end else begin
                                            L_PolarSpeedBarcodeDetails.Storage := '2-25';
                                        end;

                                        L_IUM.Reset();
                                        L_IUM.SetFilter(Code, L_Item."Base Unit of Measure");
                                        if L_IUM.FindFirst() then begin
                                            L_PolarSpeedBarcodeDetails.Weight := L_IUM.Weight;
                                        end;
                                    end;
                                end;
                            end;
                            L_PolarSpeedBarcodeDetails.Temprature := 'Ambient'; //PS only deal with Ambient Items++

                            //Print Request++
                            if L_PolarSpeedBarcodeDetails.Insert() then begin
                                L_PolarSpeedBarcodeDetails.Reset();
                                L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _RequestValues.GetValue('ToteNo'));
                                L_PolarSpeedBarcodeDetails.SetRange("Order No.", KnappOrdResponse."Document No.");
                                L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                                if L_PolarSpeedBarcodeDetails.FindFirst() then begin
                                    _DataItemViews.SetValue('Barcodes', L_PolarSpeedBarcodeDetails.GetView(false));
                                    _OptionsFieldValues.SetValue('NoOfCopies', 0);
                                    _IsHandled := true;
                                end;
                            end else
                                Error(StrSubstNo('Error: %1. Please try again', GetLastErrorText));


                        end else begin
                            //Checking Posted document if order is posted++
                            //NOTE - In sigma, One order have only one shipment and Invoice for KNAPP orders++
                            L_SalesInvoiceHeader.Reset();
                            L_SalesInvoiceHeader.SetRange("Order No.", KnappOrdResponse."Document No.");
                            if L_SalesInvoiceHeader.FindFirst() then begin
                                L_PolarSpeedBarcodeDetails.Init();
                                L_PolarSpeedBarcodeDetails."Entry No." := getlastentryno();
                                L_PolarSpeedBarcodeDetails."Tote/Order No." := _RequestValues.GetValue('ToteNo');
                                L_PolarSpeedBarcodeDetails."No. of Box / Tote Sequence" := _RequestValues.GetValueAsInteger('ToteSeq');
                                L_PolarSpeedBarcodeDetails."Order Category" := L_PolarSpeedBarcodeDetails."Order Category"::Knapp;
                                L_PolarSpeedBarcodeDetails."Customer No." := L_SalesInvoiceHeader."Sell-to Customer No.";
                                L_PolarSpeedBarcodeDetails."Order No." := L_SalesInvoiceHeader."Order No.";
                                L_PolarSpeedBarcodeDetails."Sales Invoice No." := L_SalesInvoiceHeader."No.";
                                L_PolarSpeedBarcodeDetails."Print Date" := WorkDate();
                                L_PolarSpeedBarcodeDetails."Shipment Date" := L_SalesInvoiceHeader."Shipment Date";
                                L_PolarSpeedBarcodeDetails."Barcode No." := NoSeriesMgt.GetNextNo('PSLABEL', WorkDate(), true);
                                //Get Temprature And Storage++
                                L_SalesInvoiceLine.Reset();
                                L_SalesInvoiceLine.SetRange("No.", KnappOrdResponse."Item No.");
                                L_SalesInvoiceLine.SetRange(Type, L_SalesInvoiceLine.Type::Item);
                                L_SalesInvoiceLine.SetRange("Document No.", L_SalesInvoiceHeader."No.");
                                L_SalesInvoiceLine.SetRange("Line No.", KnappOrdResponse."Line No.");
                                L_SalesInvoiceLine.SetFilter(Quantity, '>%1', 0);
                                if L_SalesInvoiceLine.FindFirst() then begin
                                    if L_Item.Get(L_SalesInvoiceLine."No.") then begin
                                        if L_Item.Storage = '2-8' then begin
                                            L_PolarSpeedBarcodeDetails.Storage := '2-8';
                                        end else begin
                                            L_PolarSpeedBarcodeDetails.Storage := '2-25';
                                        end;

                                        L_IUM.Reset();
                                        L_IUM.SetFilter(Code, L_Item."Base Unit of Measure");
                                        if L_IUM.FindFirst() then begin
                                            L_PolarSpeedBarcodeDetails.Weight := L_IUM.Weight;
                                        end;
                                    end;
                                end;
                                L_PolarSpeedBarcodeDetails.Temprature := 'Ambient'; //PS only deal with Ambient Items++

                                //Print Request++
                                if L_PolarSpeedBarcodeDetails.Insert() then begin
                                    L_PolarSpeedBarcodeDetails.Reset();
                                    L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _RequestValues.GetValue('ToteNo'));
                                    L_PolarSpeedBarcodeDetails.SetRange("Order No.", KnappOrdResponse."Document No.");
                                    L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                                    if L_PolarSpeedBarcodeDetails.FindFirst() then begin
                                        _DataItemViews.SetValue('Barcodes', L_PolarSpeedBarcodeDetails.GetView(false));
                                        _OptionsFieldValues.SetValue('NoOfCopies', 0);
                                        _IsHandled := true;
                                    end;
                                end else
                                    Error(StrSubstNo('Error: %1. Please try again', GetLastErrorText));
                            end;
                        end;
                    end else begin
                        // //Print Label if exist+++
                        // L_PolarSpeedBarcodeDetails.Reset();
                        // L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _RequestValues.GetValue('ToteNo'));
                        // L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                        // if L_PolarSpeedBarcodeDetails.FindFirst() then begin
                        //     _DataItemViews.SetValue('Barcodes', L_PolarSpeedBarcodeDetails.GetView(false));
                        //     _OptionsFieldValues.SetValue('NoOfCopies', 0);
                        //     _IsHandled := true;
                        // end;

                        //Reprint not allowed+++
                        Error('This label has already been printed/No label to print. Contact supervisor.');
                        _IsHandled := true;
                    end;
                end;

                //++
                DuplicateOrderNo := KnappOrdResponse."Document No.";
            until KnappOrdResponse.Next() = 0;
        end else
            Error('This label has already been printed/No label to print. Contact supervisor.');
    end;
    #EndRegion For KNAPP PS Label++


    #Region For Manual PS Label++
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Report Print Lookup", 'OnLookupOnPrintReport_OnAddStepsForReport', '', true, true)]
    local procedure OnLookupOnPrintReport_OnAddStepsForManualLabel(_MobReport: Record "MOB Report"; var _RequestValues: Record "MOB NS Request Element"; _SourceRecRef: RecordRef; var _Steps: Record "MOB Steps Element"; var _IsHandled: Boolean)
    var
        MobReportPrintSteps: Codeunit "MOB Report Print Lookup";
    begin
        if _MobReport."RequestPage Handler" = _MobReport."RequestPage Handler"::"PolarSpeed Label2" then begin

            _Steps.Create_TextStep(10, 'OrderNo');
            _Steps.Set_header('Inv. Pick No.');
            _Steps.Set_label('Inv. Pick No.:');

            MobReportPrintSteps.CreateReportPrinterAndNoOfCopiesSteps(_MobReport, _RequestValues, _Steps, 90, 0);
            _IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB ReportParameters Mgt.", 'OnCreateReportParameters', '', true, true)]
    local procedure OnCreateReportParametersManualLabel(_MobReport: Record "Mob Report"; _SourceRecRef: RecordRef; var _RequestValues: Record "MOB NS Request Element" temporary; var _OptionsFieldValues: Record "MOB ReportParameters Element"; var _DataItemViews: Record "MOB ReportParameters Element"; var _IsHandled: Boolean)
    var
        L_PolarSpeedBarcodeDetails: Record "Polar Speed Barcode Details";
        Last_PolarSpeedBarcodeDetails: Record "Polar Speed Barcode Details";
        NoSeriesMgt: Codeunit "No. Series";
        SalesShipHDR: Record "Sales Shipment Header";
        SalesInvHDR: Record "Sales Invoice Header";
        L_SalesInvoiceLine: Record "Sales Invoice Line";
        i: Integer;
        L_Box: Integer;
        L_Item: Record Item;
        L_count: integer;
        L_Diff: Integer;
        L_IUM: Record "Item Unit of Measure";
    begin
        if _MobReport."RequestPage Handler" <> _MobReport."RequestPage Handler"::"PolarSpeed Label2" then
            exit;

        //clear Variable++
        Clear(L_Box);

        //Create PS label Details & Print the label+++ 
        SalesShipHDR.Reset();
        SalesShipHDR.SetRange("Inv. Pick No.", _RequestValues.GetValue('OrderNo'));//Inv. Pick Number
        if SalesShipHDR.FindFirst() then begin
            L_PolarSpeedBarcodeDetails.Reset();
            L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", SalesShipHDR."Inv. Pick No.");
            L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
            if not L_PolarSpeedBarcodeDetails.FindFirst() then begin
                L_Box := SalesShipHDR."No of Boxes";
                if L_Box = 0 then
                    L_Box := 1;
                //++
                for i := 1 to L_Box do begin
                    L_PolarSpeedBarcodeDetails.Init();
                    L_PolarSpeedBarcodeDetails."Entry No." := getlastentryno();
                    L_PolarSpeedBarcodeDetails."Tote/Order No." := _RequestValues.GetValue('OrderNo');
                    L_PolarSpeedBarcodeDetails."Order Category" := L_PolarSpeedBarcodeDetails."Order Category"::Manual;
                    L_PolarSpeedBarcodeDetails."Customer No." := SalesShipHDR."Sell-to Customer No.";
                    L_PolarSpeedBarcodeDetails."Order No." := SalesShipHDR."Order No.";
                    L_PolarSpeedBarcodeDetails."Shipment Date" := SalesShipHDR."Shipment Date";
                    L_PolarSpeedBarcodeDetails."No. of Box / Tote Sequence" := i;
                    L_PolarSpeedBarcodeDetails."Print Date" := WorkDate();
                    L_PolarSpeedBarcodeDetails."Barcode No." := NoSeriesMgt.GetNextNo('PSLABEL', WorkDate(), true);

                    //Note - _RequestValues.GetValue('OrderNo') = Inv. Pick No.; Link between Sales Invoice Header, so using this filter to get Sales Invoice No.++
                    SalesInvHDR.Reset();
                    SalesInvHDR.SetRange("Inv. Pick No.", _RequestValues.GetValue('OrderNo'));
                    if SalesInvHDR.FindFirst() then begin
                        L_PolarSpeedBarcodeDetails."Sales Invoice No." := SalesInvHDR."No.";

                        //Get Temprature & Storage++
                        L_SalesInvoiceLine.Reset();
                        L_SalesInvoiceLine.SetRange("Document No.", SalesInvHDR."No.");
                        if L_SalesInvoiceLine.FindFirst() then begin
                            if L_Item.Get(L_SalesInvoiceLine."No.") then begin
                                if L_Item.Storage = '2-8' then begin
                                    L_PolarSpeedBarcodeDetails.Storage := '2-8';
                                end else begin
                                    L_PolarSpeedBarcodeDetails.Storage := '2-25';
                                end;

                                L_IUM.Reset();
                                L_IUM.SetFilter(Code, L_Item."Base Unit of Measure");
                                if L_IUM.FindFirst() then begin
                                    L_PolarSpeedBarcodeDetails.Weight := L_IUM.Weight;
                                end;
                            end;
                        end;
                        L_PolarSpeedBarcodeDetails.Temprature := 'Ambient'; //PS only deal with Ambient Items++
                    end;
                    L_PolarSpeedBarcodeDetails.Insert()
                end;

                //Print Request++
                L_PolarSpeedBarcodeDetails.Reset();
                L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _RequestValues.GetValue('OrderNo'));
                L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                if L_PolarSpeedBarcodeDetails.FindSet() then begin
                    _DataItemViews.SetValue('Barcodes', L_PolarSpeedBarcodeDetails.GetView(false));
                    _OptionsFieldValues.SetValue('NoOfCopies', 0);
                    _IsHandled := true;
                end;
            end else begin
                //Print Label if exist+++
                Clear(L_count);
                L_PolarSpeedBarcodeDetails.Reset();
                L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _RequestValues.GetValue('OrderNo'));
                L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                if L_PolarSpeedBarcodeDetails.FindSet() then
                    L_count := L_PolarSpeedBarcodeDetails.Count;

                SalesShipHDR.Reset();
                SalesShipHDR.SetRange("Inv. Pick No.", _RequestValues.GetValue('OrderNo'));//Inv. Pick Number
                if SalesShipHDR.FindFirst() then begin
                    if L_count <= SalesShipHDR."No of Boxes" then begin
                        //++
                        if L_count = SalesShipHDR."No of Boxes" then
                            Error('This label has already been printed/No label to print. Contact supervisor.');


                        //++
                        L_Box := SalesShipHDR."No of Boxes" - L_count;
                        for i := 1 to L_Box do begin
                            L_PolarSpeedBarcodeDetails.Init();
                            L_PolarSpeedBarcodeDetails."Entry No." := getlastentryno();
                            L_PolarSpeedBarcodeDetails."Tote/Order No." := _RequestValues.GetValue('OrderNo');
                            L_PolarSpeedBarcodeDetails."Order Category" := L_PolarSpeedBarcodeDetails."Order Category"::Manual;
                            L_PolarSpeedBarcodeDetails."Customer No." := SalesShipHDR."Sell-to Customer No.";
                            L_PolarSpeedBarcodeDetails."Order No." := SalesShipHDR."Order No.";
                            L_PolarSpeedBarcodeDetails."Shipment Date" := SalesShipHDR."Shipment Date";
                            //++
                            Last_PolarSpeedBarcodeDetails.Reset();
                            Last_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _RequestValues.GetValue('OrderNo'));
                            if Last_PolarSpeedBarcodeDetails.FindLast() then
                                L_PolarSpeedBarcodeDetails."No. of Box / Tote Sequence" := Last_PolarSpeedBarcodeDetails."No. of Box / Tote Sequence" + 1;
                            L_PolarSpeedBarcodeDetails."Print Date" := WorkDate();
                            L_PolarSpeedBarcodeDetails."Barcode No." := NoSeriesMgt.GetNextNo('PSLABEL', WorkDate(), true);

                            //Note -  _RequestValues.GetValue('OrderNo') = Inv. Pick No.; Link between Sales Invoice Header, so using this filter to get Sales Invoice No.++
                            SalesInvHDR.Reset();
                            SalesInvHDR.SetRange("Inv. Pick No.", _RequestValues.GetValue('OrderNo'));
                            if SalesInvHDR.FindFirst() then begin
                                L_PolarSpeedBarcodeDetails."Sales Invoice No." := SalesInvHDR."No.";

                                //Get Temprature & Storage++
                                L_SalesInvoiceLine.Reset();
                                L_SalesInvoiceLine.SetRange("Document No.", SalesInvHDR."No.");
                                if L_SalesInvoiceLine.FindFirst() then begin
                                    if L_Item.Get(L_SalesInvoiceLine."No.") then begin
                                        if L_Item.Storage = '2-8' then begin
                                            L_PolarSpeedBarcodeDetails.Storage := '2-8';
                                        end else begin
                                            L_PolarSpeedBarcodeDetails.Storage := '2-25';
                                        end;

                                        L_IUM.Reset();
                                        L_IUM.SetFilter(Code, L_Item."Base Unit of Measure");
                                        if L_IUM.FindFirst() then begin
                                            L_PolarSpeedBarcodeDetails.Weight := L_IUM.Weight;
                                        end;
                                    end;
                                end;
                                L_PolarSpeedBarcodeDetails.Temprature := 'Ambient'; //PS only deal with Ambient Items++
                            end;
                            L_PolarSpeedBarcodeDetails.Insert();
                        end;
                    end else begin
                        // if L_count > SalesShipHDR."No of Boxes" then begin
                        //     L_Diff := L_count - SalesShipHDR."No of Boxes";
                        //     L_PolarSpeedBarcodeDetails.Reset();
                        //     L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _Barcode);
                        //     L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                        //     L_PolarSpeedBarcodeDetails.SetCurrentKey("Entry No.");
                        //     L_PolarSpeedBarcodeDetails.Ascending(false);
                        //     if L_PolarSpeedBarcodeDetails.FindSet() then begin
                        //         repeat
                        //             L_PolarSpeedBarcodeDetails.Delete();
                        //             L_Diff := L_Diff - 1;
                        //         until (L_Diff = 0) or (L_PolarSpeedBarcodeDetails.Next() = 0);
                        //     end;
                        // end;

                    end;
                end;

                //Print Request++
                L_PolarSpeedBarcodeDetails.Reset();
                L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _RequestValues.GetValue('OrderNo'));
                L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                L_PolarSpeedBarcodeDetails.SetRange("No. Printed", 0);
                if L_PolarSpeedBarcodeDetails.FindSet() then begin
                    _DataItemViews.SetValue('Barcodes', L_PolarSpeedBarcodeDetails.GetView(false));
                    _OptionsFieldValues.SetValue('NoOfCopies', 0);
                    _IsHandled := true;
                end;
            end;
        end else
            Error('This label has already been printed/No label to print. Contact supervisor.');
    end;
    #EndRegion For Manual PS Label++

    //Manual option to create the details++
    procedure Manual_CreateEentryInPSdetailstable(_Barcode: Code[50]; _ToteSequence: Integer; _OrderCategory: Option " ",Manual,Knapp)
    var
        L_PolarSpeedBarcodeDetails: Record "Polar Speed Barcode Details";
        NoSeriesMgt: Codeunit "No. Series";
        SalesShipHDR: Record "Sales Shipment Header";
        SalesInvHDR: Record "Sales Invoice Header";
        L_SalesInvoiceLine: Record "Sales Invoice Line";
        i: Integer;
        L_Box: Integer;
        L_Item: Record Item;
        L_count: integer;
        L_Diff: Integer;
        PolarItemLabel: Report "Polar Item Label";
        Last_PolarSpeedBarcodeDetails: Record "Polar Speed Barcode Details";
        KnappOrdResponse: Record "Knapp Order Response";
        SalesHeader: Record "Sales Header";
        L_SalesInvoiceHeader: Record "Sales Invoice Header";
        OrderNoFilter: Code[2000];
        DuplicateOrderNo: Code[2000];
        L_SalesLine: Record "Sales Line";
        L_IUM: Record "Item Unit of Measure";
    begin
        case _OrderCategory of
            _OrderCategory::Manual:
                begin
                    //clear Variable++
                    Clear(L_Box);

                    //Create PS label Details & Print the label+++ 
                    SalesShipHDR.Reset();
                    SalesShipHDR.SetRange("Inv. Pick No.", _Barcode);//Inv. Pick Number
                    if SalesShipHDR.FindFirst() then begin
                        L_PolarSpeedBarcodeDetails.Reset();
                        L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", SalesShipHDR."Inv. Pick No.");
                        L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                        if not L_PolarSpeedBarcodeDetails.FindFirst() then begin
                            L_Box := SalesShipHDR."No of Boxes";
                            if L_Box = 0 then
                                L_Box := 1;
                            //++
                            for i := 1 to L_Box do begin
                                L_PolarSpeedBarcodeDetails.Init();
                                L_PolarSpeedBarcodeDetails."Entry No." := getlastentryno();
                                L_PolarSpeedBarcodeDetails."Tote/Order No." := _Barcode;
                                L_PolarSpeedBarcodeDetails."Order Category" := L_PolarSpeedBarcodeDetails."Order Category"::Manual;
                                L_PolarSpeedBarcodeDetails."Customer No." := SalesShipHDR."Sell-to Customer No.";
                                L_PolarSpeedBarcodeDetails."Order No." := SalesShipHDR."Order No.";
                                L_PolarSpeedBarcodeDetails."Shipment Date" := SalesShipHDR."Shipment Date";
                                L_PolarSpeedBarcodeDetails."No. of Box / Tote Sequence" := i;
                                L_PolarSpeedBarcodeDetails."Print Date" := WorkDate();
                                L_PolarSpeedBarcodeDetails."Barcode No." := NoSeriesMgt.GetNextNo('PSLABEL', WorkDate(), true);

                                //Note - _Barcode = Inv. Pick No.; Link between Sales Invoice Header, so using this filter to get Sales Invoice No.++
                                SalesInvHDR.Reset();
                                SalesInvHDR.SetRange("Inv. Pick No.", _Barcode);
                                if SalesInvHDR.FindFirst() then begin
                                    L_PolarSpeedBarcodeDetails."Sales Invoice No." := SalesInvHDR."No.";

                                    //Get Temprature & Storage++
                                    L_SalesInvoiceLine.Reset();
                                    L_SalesInvoiceLine.SetRange("Document No.", SalesInvHDR."No.");
                                    if L_SalesInvoiceLine.FindFirst() then begin
                                        if L_Item.Get(L_SalesInvoiceLine."No.") then begin
                                            if L_Item.Storage = '2-8' then begin
                                                L_PolarSpeedBarcodeDetails.Storage := '2-8';
                                            end else begin
                                                L_PolarSpeedBarcodeDetails.Storage := '2-25';
                                            end;

                                            L_IUM.Reset();
                                            L_IUM.SetFilter(Code, L_Item."Base Unit of Measure");
                                            if L_IUM.FindFirst() then begin
                                                L_PolarSpeedBarcodeDetails.Weight := L_IUM.Weight;
                                            end;
                                        end;
                                    end;
                                    L_PolarSpeedBarcodeDetails.Temprature := 'Ambient'; //PS only deal with Ambient Items++
                                end;
                                L_PolarSpeedBarcodeDetails.Insert()
                            end;

                            //Print Request++
                            Clear(PolarItemLabel);
                            L_PolarSpeedBarcodeDetails.Reset();
                            L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _Barcode);
                            L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                            if L_PolarSpeedBarcodeDetails.FindSet() then begin
                                PolarItemLabel.SetTableView(L_PolarSpeedBarcodeDetails);
                                PolarItemLabel.UseRequestPage(false);
                                PolarItemLabel.Run();
                            end;
                        end else begin
                            Clear(L_count);
                            L_PolarSpeedBarcodeDetails.Reset();
                            L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _Barcode);
                            L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                            if L_PolarSpeedBarcodeDetails.FindSet() then
                                L_count := L_PolarSpeedBarcodeDetails.Count;

                            SalesShipHDR.Reset();
                            SalesShipHDR.SetRange("Inv. Pick No.", _Barcode);//Inv. Pick Number
                            if SalesShipHDR.FindFirst() then begin
                                if L_count <= SalesShipHDR."No of Boxes" then begin
                                    //++
                                    if L_count = SalesShipHDR."No of Boxes" then
                                        Error('You do not have permission to reprint the label. Please contact the admin team.');


                                    //++
                                    L_Box := SalesShipHDR."No of Boxes" - L_count;
                                    for i := 1 to L_Box do begin
                                        L_PolarSpeedBarcodeDetails.Init();
                                        L_PolarSpeedBarcodeDetails."Entry No." := getlastentryno();
                                        L_PolarSpeedBarcodeDetails."Tote/Order No." := _Barcode;
                                        L_PolarSpeedBarcodeDetails."Order Category" := L_PolarSpeedBarcodeDetails."Order Category"::Manual;
                                        L_PolarSpeedBarcodeDetails."Customer No." := SalesShipHDR."Sell-to Customer No.";
                                        L_PolarSpeedBarcodeDetails."Order No." := SalesShipHDR."Order No.";
                                        L_PolarSpeedBarcodeDetails."Shipment Date" := SalesShipHDR."Shipment Date";
                                        //++
                                        Last_PolarSpeedBarcodeDetails.Reset();
                                        Last_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _Barcode);
                                        if Last_PolarSpeedBarcodeDetails.FindLast() then
                                            L_PolarSpeedBarcodeDetails."No. of Box / Tote Sequence" := Last_PolarSpeedBarcodeDetails."No. of Box / Tote Sequence" + 1;
                                        L_PolarSpeedBarcodeDetails."Print Date" := WorkDate();
                                        L_PolarSpeedBarcodeDetails."Barcode No." := NoSeriesMgt.GetNextNo('PSLABEL', WorkDate(), true);

                                        //Note - _Barcode = Inv. Pick No.; Link between Sales Invoice Header, so using this filter to get Sales Invoice No.++
                                        SalesInvHDR.Reset();
                                        SalesInvHDR.SetRange("Inv. Pick No.", _Barcode);
                                        if SalesInvHDR.FindFirst() then begin
                                            L_PolarSpeedBarcodeDetails."Sales Invoice No." := SalesInvHDR."No.";

                                            //Get Temprature & Storage++
                                            L_SalesInvoiceLine.Reset();
                                            L_SalesInvoiceLine.SetRange("Document No.", SalesInvHDR."No.");
                                            if L_SalesInvoiceLine.FindFirst() then begin
                                                if L_Item.Get(L_SalesInvoiceLine."No.") then begin
                                                    if L_Item.Storage = '2-8' then begin
                                                        L_PolarSpeedBarcodeDetails.Storage := '2-8';
                                                    end else begin
                                                        L_PolarSpeedBarcodeDetails.Storage := '2-25';
                                                    end;

                                                    L_IUM.Reset();
                                                    L_IUM.SetFilter(Code, L_Item."Base Unit of Measure");
                                                    if L_IUM.FindFirst() then begin
                                                        L_PolarSpeedBarcodeDetails.Weight := L_IUM.Weight;
                                                    end;
                                                end;
                                            end;
                                            L_PolarSpeedBarcodeDetails.Temprature := 'Ambient'; //PS only deal with Ambient Items++
                                        end;
                                        L_PolarSpeedBarcodeDetails.Insert();
                                    end;

                                end else begin
                                    // if L_count > SalesShipHDR."No of Boxes" then begin
                                    //     L_Diff := L_count - SalesShipHDR."No of Boxes";
                                    //     L_PolarSpeedBarcodeDetails.Reset();
                                    //     L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _Barcode);
                                    //     L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                                    //     L_PolarSpeedBarcodeDetails.SetCurrentKey("Entry No.");
                                    //     L_PolarSpeedBarcodeDetails.Ascending(false);
                                    //     if L_PolarSpeedBarcodeDetails.FindSet() then begin
                                    //         repeat
                                    //             L_PolarSpeedBarcodeDetails.Delete();
                                    //             L_Diff := L_Diff - 1;
                                    //         until (L_Diff = 0) or (L_PolarSpeedBarcodeDetails.Next() = 0);
                                    //     end;
                                    // end;

                                end;
                            end;


                            //Print Request++
                            Clear(PolarItemLabel);
                            L_PolarSpeedBarcodeDetails.Reset();
                            L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _Barcode);
                            L_PolarSpeedBarcodeDetails.SetRange("No. Printed", 0);
                            L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                            if L_PolarSpeedBarcodeDetails.FindSet() then begin
                                PolarItemLabel.SetTableView(L_PolarSpeedBarcodeDetails);
                                PolarItemLabel.UseRequestPage(false);
                                PolarItemLabel.Run();
                            end;
                        end;
                    end else
                        Error('You do not have permission to reprint the label. Please contact the admin team.');
                end;
            _OrderCategory::Knapp:
                begin
                    #Region Check Tote sequence is already available for scanned tote and same day+++
                    Clear(OrderNoFilter);
                    Clear(DuplicateOrderNo);
                    KnappOrdResponse.Reset();
                    KnappOrdResponse.SetRange("Document Type", KnappOrdResponse."Document Type"::Order);
                    KnappOrdResponse.SetRange("Load Unit", _Barcode);
                    KnappOrdResponse.SetFilter(Quantity, '>%1', 0);
                    KnappOrdResponse.SetRange("PS Label Exist", false);
                    KnappOrdResponse.SetFilter(SystemCreatedAt, '%1..%2', CreateDateTime(WorkDate(), 000000T), CreateDateTime(WorkDate(), 235959T));
                    if KnappOrdResponse.FindSet() then begin
                        repeat
                            if OrderNoFilter <> '' then begin
                                if DuplicateOrderNo <> KnappOrdResponse."Document No." then begin
                                    OrderNoFilter := '|' + KnappOrdResponse."Document No.";
                                    DuplicateOrderNo := KnappOrdResponse."Document No.";
                                end;
                            end else begin
                                OrderNoFilter := KnappOrdResponse."Document No.";
                                DuplicateOrderNo := KnappOrdResponse."Document No.";
                            end;
                        until KnappOrdResponse.Next() = 0;
                        if OrderNoFilter = '' then
                            Error('No label to print');


                        //Check Duplicat Tote sequence+++
                        L_PolarSpeedBarcodeDetails.Reset();
                        L_PolarSpeedBarcodeDetails.SetFilter("Order No.", OrderNoFilter);
                        L_PolarSpeedBarcodeDetails.SetRange("No. of Box / Tote Sequence", _ToteSequence);
                        L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                        if L_PolarSpeedBarcodeDetails.FindSet() then
                            repeat
                                if L_PolarSpeedBarcodeDetails."Tote/Order No." <> _Barcode then
                                    Error('The tote sequence %1 already exists for tote %2', L_PolarSpeedBarcodeDetails."No. of Box / Tote Sequence", L_PolarSpeedBarcodeDetails."Tote/Order No.");
                            until L_PolarSpeedBarcodeDetails.Next() = 0;
                    end;
                    #EndRegion Check Tote sequence is already available for scanned tote and same day+++


                    //Create PS label Details & Print the label+++ 
                    Clear(DuplicateOrderNo);
                    KnappOrdResponse.Reset();
                    KnappOrdResponse.SetRange("Document Type", KnappOrdResponse."Document Type"::Order);
                    KnappOrdResponse.SetRange("Load Unit", _Barcode);
                    KnappOrdResponse.SetFilter(Quantity, '>%1', 0);
                    KnappOrdResponse.SetRange("PS Label Exist", false);
                    KnappOrdResponse.SetFilter(SystemCreatedAt, '%1..%2', CreateDateTime(WorkDate(), 000000T), CreateDateTime(WorkDate(), 235959T));
                    KnappOrdResponse.SetCurrentKey("Document No.");
                    KnappOrdResponse.Ascending(true);
                    if KnappOrdResponse.FindSet() then begin
                        repeat
                            if DuplicateOrderNo <> KnappOrdResponse."Document No." then begin
                                L_PolarSpeedBarcodeDetails.Reset();
                                L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", KnappOrdResponse."Load Unit");
                                L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                                L_PolarSpeedBarcodeDetails.SetRange("Order No.", KnappOrdResponse."Document No.");
                                if not L_PolarSpeedBarcodeDetails.FindFirst() then begin
                                    SalesHeader.Reset();
                                    SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
                                    SalesHeader.SetRange("No.", KnappOrdResponse."Document No.");
                                    if SalesHeader.FindFirst() then begin
                                        L_PolarSpeedBarcodeDetails.Init();
                                        L_PolarSpeedBarcodeDetails."Entry No." := getlastentryno();
                                        L_PolarSpeedBarcodeDetails."Tote/Order No." := _Barcode;
                                        L_PolarSpeedBarcodeDetails."No. of Box / Tote Sequence" := _ToteSequence;
                                        L_PolarSpeedBarcodeDetails."Order Category" := L_PolarSpeedBarcodeDetails."Order Category"::Knapp;
                                        L_PolarSpeedBarcodeDetails."Customer No." := SalesHeader."Sell-to Customer No.";
                                        L_PolarSpeedBarcodeDetails."Order No." := SalesHeader."No.";

                                        //NOTE - In sigma, One order have only one shipment and Invoice for KNAPP orders++
                                        L_SalesInvoiceHeader.Reset();
                                        L_SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
                                        if L_SalesInvoiceHeader.FindFirst() then begin
                                            L_PolarSpeedBarcodeDetails."Sales Invoice No." := L_SalesInvoiceHeader."No.";
                                        end else
                                            L_PolarSpeedBarcodeDetails."Sales Invoice No." := SalesHeader."Posting No.";

                                        L_PolarSpeedBarcodeDetails."Print Date" := WorkDate();
                                        L_PolarSpeedBarcodeDetails."Shipment Date" := SalesHeader."Shipment Date";
                                        L_PolarSpeedBarcodeDetails."Barcode No." := NoSeriesMgt.GetNextNo('PSLABEL', WorkDate(), true);

                                        //Get Temprature And Storage++
                                        L_SalesLine.Reset();
                                        L_SalesLine.SetRange("No.", KnappOrdResponse."Item No.");
                                        L_SalesLine.SetRange(Type, L_SalesLine.Type::Item);
                                        L_SalesLine.SetRange("Document No.", KnappOrdResponse."Document No.");
                                        L_SalesLine.SetRange("Line No.", KnappOrdResponse."Line No.");
                                        if L_SalesLine.FindFirst() then begin
                                            if L_Item.Get(L_SalesLine."No.") then begin
                                                if L_Item.Storage = '2-8' then begin
                                                    L_PolarSpeedBarcodeDetails.Storage := '2-8';
                                                end else begin
                                                    L_PolarSpeedBarcodeDetails.Storage := '2-25';
                                                end;

                                                L_IUM.Reset();
                                                L_IUM.SetFilter(Code, L_Item."Base Unit of Measure");
                                                if L_IUM.FindFirst() then begin
                                                    L_PolarSpeedBarcodeDetails.Weight := L_IUM.Weight;
                                                end;
                                            end;
                                        end else begin
                                            //NOTE - In sigma, One order have only one shipment and Invoice for KNAPP orders++
                                            L_SalesInvoiceLine.Reset();
                                            L_SalesInvoiceLine.SetRange("Order No.", KnappOrdResponse."Document No.");
                                            L_SalesInvoiceLine.SetRange("Line No.", KnappOrdResponse."Line No.");
                                            L_SalesInvoiceLine.SetRange(Type, L_SalesInvoiceLine.Type::Item);
                                            L_SalesInvoiceLine.SetFilter(Quantity, '>%1', 0);
                                            if L_SalesInvoiceLine.FindFirst() then begin
                                                if L_Item.Get(L_SalesInvoiceLine."No.") then begin
                                                    if L_Item.Storage = '2-8' then begin
                                                        L_PolarSpeedBarcodeDetails.Storage := '2-8';
                                                    end else begin
                                                        L_PolarSpeedBarcodeDetails.Storage := '2-25';
                                                    end;

                                                    L_IUM.Reset();
                                                    L_IUM.SetFilter(Code, L_Item."Base Unit of Measure");
                                                    if L_IUM.FindFirst() then begin
                                                        L_PolarSpeedBarcodeDetails.Weight := L_IUM.Weight;
                                                    end;
                                                end;
                                            end;
                                        end;
                                        L_PolarSpeedBarcodeDetails.Temprature := 'Ambient'; //PS only deal with Ambient Items++

                                        //Print Request++
                                        Clear(PolarItemLabel);
                                        if L_PolarSpeedBarcodeDetails.Insert() then begin
                                            L_PolarSpeedBarcodeDetails.Reset();
                                            L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _Barcode);
                                            L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                                            L_PolarSpeedBarcodeDetails.SetRange("Order No.", KnappOrdResponse."Document No.");
                                            if L_PolarSpeedBarcodeDetails.FindFirst() then begin
                                                PolarItemLabel.SetTableView(L_PolarSpeedBarcodeDetails);
                                                PolarItemLabel.UseRequestPage(false);
                                                PolarItemLabel.Run();
                                            end;
                                        end else
                                            Error(StrSubstNo('Error: %1. Please try again', GetLastErrorText));


                                    end else begin
                                        //Checking Posted document if order is posted++
                                        //NOTE - In sigma, One order have only one shipment and Invoice for KNAPP orders++
                                        L_SalesInvoiceHeader.Reset();
                                        L_SalesInvoiceHeader.SetRange("Order No.", KnappOrdResponse."Document No.");
                                        if L_SalesInvoiceHeader.FindFirst() then begin
                                            L_PolarSpeedBarcodeDetails.Init();
                                            L_PolarSpeedBarcodeDetails."Entry No." := getlastentryno();
                                            L_PolarSpeedBarcodeDetails."Tote/Order No." := _Barcode;
                                            L_PolarSpeedBarcodeDetails."No. of Box / Tote Sequence" := _ToteSequence;
                                            L_PolarSpeedBarcodeDetails."Order Category" := L_PolarSpeedBarcodeDetails."Order Category"::Knapp;
                                            L_PolarSpeedBarcodeDetails."Customer No." := L_SalesInvoiceHeader."Sell-to Customer No.";
                                            L_PolarSpeedBarcodeDetails."Order No." := L_SalesInvoiceHeader."Order No.";
                                            L_PolarSpeedBarcodeDetails."Sales Invoice No." := L_SalesInvoiceHeader."No.";
                                            L_PolarSpeedBarcodeDetails."Print Date" := WorkDate();
                                            L_PolarSpeedBarcodeDetails."Shipment Date" := L_SalesInvoiceHeader."Shipment Date";
                                            L_PolarSpeedBarcodeDetails."Barcode No." := NoSeriesMgt.GetNextNo('PSLABEL', WorkDate(), true);
                                            //Get Temprature And Storage++
                                            //NOTE - In sigma, One order have only one shipment and Invoice for KNAPP orders++
                                            L_SalesInvoiceLine.Reset();
                                            L_SalesInvoiceLine.SetRange("Document No.", L_SalesInvoiceHeader."No.");
                                            L_SalesInvoiceLine.SetRange("Line No.", KnappOrdResponse."Line No.");
                                            L_SalesInvoiceLine.SetRange(Type, L_SalesInvoiceLine.Type::Item);
                                            L_SalesInvoiceLine.SetFilter(Quantity, '>%1', 0);
                                            if L_SalesInvoiceLine.FindFirst() then begin
                                                if L_Item.Get(L_SalesInvoiceLine."No.") then begin
                                                    if L_Item.Storage = '2-8' then begin
                                                        L_PolarSpeedBarcodeDetails.Storage := '2-8';
                                                    end else begin
                                                        L_PolarSpeedBarcodeDetails.Storage := '2-25';
                                                    end;

                                                    L_IUM.Reset();
                                                    L_IUM.SetFilter(Code, L_Item."Base Unit of Measure");
                                                    if L_IUM.FindFirst() then begin
                                                        L_PolarSpeedBarcodeDetails.Weight := L_IUM.Weight;
                                                    end;
                                                end;
                                            end;
                                            L_PolarSpeedBarcodeDetails.Temprature := 'Ambient'; //PS only deal with Ambient Items++

                                            //Print Request++
                                            Clear(PolarItemLabel);
                                            if L_PolarSpeedBarcodeDetails.Insert() then begin
                                                L_PolarSpeedBarcodeDetails.Reset();
                                                L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _Barcode);
                                                L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                                                L_PolarSpeedBarcodeDetails.SetRange("Order No.", KnappOrdResponse."Document No.");
                                                if L_PolarSpeedBarcodeDetails.FindFirst() then begin
                                                    PolarItemLabel.SetTableView(L_PolarSpeedBarcodeDetails);
                                                    PolarItemLabel.UseRequestPage(false);
                                                    PolarItemLabel.Run();
                                                end;
                                            end else
                                                Error(StrSubstNo('Error: %1. Please try again', GetLastErrorText));
                                        end;
                                    end;
                                end else begin
                                    // //Print Label if exist+++
                                    // Clear(PolarItemLabel);
                                    // L_PolarSpeedBarcodeDetails.Reset();
                                    // L_PolarSpeedBarcodeDetails.SetRange("Tote/Order No.", _Barcode);
                                    // L_PolarSpeedBarcodeDetails.SetRange("Print Date", WorkDate());
                                    // L_PolarSpeedBarcodeDetails.SetRange("Order No.", KnappOrdResponse."Document No.");
                                    // if L_PolarSpeedBarcodeDetails.FindFirst() then begin
                                    //     PolarItemLabel.SetTableView(L_PolarSpeedBarcodeDetails);
                                    //     PolarItemLabel.UseRequestPage(false);
                                    //     PolarItemLabel.Run();
                                    // end;

                                    //Reprint not allowed+++
                                    Error('You do not have permission to reprint the label. Please contact the admin team.');
                                end;
                            end;

                            //++
                            DuplicateOrderNo := KnappOrdResponse."Document No.";
                        until KnappOrdResponse.Next() = 0;
                    end else
                        Error('No label to print / You do not have permission to reprint the label. Please contact the admin team.');
                end;

        end;
    end;

    local procedure getlastentryno(): Integer
    var
        barcode: Record "Polar Speed Barcode details";
    begin
        barcode.Reset();
        if barcode.FindLast() then
            exit(barcode."Entry No." + 1)
        else
            exit(1);
    end;
}