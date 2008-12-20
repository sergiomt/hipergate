' WAB Instance
Dim oWAB
Dim iSelectedEntry
Dim iTotalEntries

WAB_Version = "1.0"

Function WAB_Count()
 WAB_Count = oWAB.GetCount()
End Function

Sub WAB_Start()
 Set oWAB = CreateObject("warjo.wab")
 oWAB.Open ""

 iTotalEntries = oWAB.GetCount()
 WAB_Select 0
End Sub

Sub WAB_Stop()
 WAB_Counter = 0
 oWAB.Close
 Set oWAB = Nothing
End Sub

Function WAB_Total()
 WAB_Total = iTotalEntries
End Function

Function WAB_Get(propertyname)

 If propertyname = "FirstName" Then
   WAB_Get = Split(oWAB.GetValue("Name"))(0)
 ElseIf propertyname = "Surname" Then
   If Len(oWAB.GetValue("Surname"))>0 Then
     WAB_Get = oWAB.GetValue("Surname")
   Else
     name_parts = UBound(Split(oWAB.GetValue("Name")))
     If name_parts>0 Then
       WAB_Get = Split(oWAB.GetValue("Name"))(name_parts) 
     Else
       WAB_Get = ""
     End If
   End If
 Else
  WAB_Get = oWAB.GetValue(propertyname)
 End If

End Function

Function WAB_SelectedEntry()
 WAB_SelectedEntry = iSelectedEntry
End Function

Function WAB_Select(entryposition)
 
 If entryposition < iTotalEntries And entryposition > -1 Then
  oWAB.Select(entryposition)
  iSelectedEntry = entryposition
 Else
  iSelectedEntry = -1
 End If

 WAB_Select = iSelectedEntry
End Function


Function WAB_XML()
 Dim sContact
 Dim sAddress

 ' Contact Data
 sContact = sContact & "<tx_name>" & Left(WAB_Get("FirstName"),100) & "</tx_name>" & vbCrLf
 sContact = sContact & "<tx_surname>" & Left(WAB_Get("Surname"),100) & "</tx_surname>" & vbCrLf
 sContact = sContact & "<de_title>" & WAB_Get("Title") & "</de_title>" & vbCrLf
 sContact = sContact & "<tx_dept>" & WAB_Get("Department") & "</tx_dept>" & vbCrLf
 sContact = sContact & "<tx_location>" & WAB_Get("Province") & "</tx_location>" & vbCrLf
 sContact = sContact & "<work_phone>" & Left(WAB_Get("HomePhone"),16) & "</work_phone>" & vbCrLf
 sContact = sContact & "<home_phone>" & Left(WAB_Get("BusinessPhone"),16) & "</home_phone>" & vbCrLf
 sContact = sContact & "<tx_email>" & Left(WAB_Get("HomeEmail"),100) & "</tx_email>" & vbCrLf

 ' Address Data

 sAddress = sAddress & "<nm_company>" & Left(WAB_Get("CompanyName"),70) & "</nm_company>" & vbCrLf
 sAddress = sAddress & "<nm_street>" & Left(WAB_Get("BusinessAddress"),100) & "</nm_street>" & vbCrLf
 sAddress = sAddress & "<nm_country>" & WAB_Get("Country") & "</nm_country>" & vbCrLf
 sAddress = sAddress & "<nm_state>" & WAB_Get("Province") & "</nm_state>" & vbCrLf
 sAddress = sAddress & "<nm_city>" & WAB_Get("City") & "</nm_city>" & vbCrLf
 sAddress = sAddress & "<work_phone>" & Left(WAB_Get("BusinessPhone"),16) & "</work_phone>" & vbCrLf
 sAddress = sAddress & "<home_phone>" & Left(WAB_Get("HomePhone"),16) & "</home_phone>" & vbCrLf
 sAddress = sAddress & "<mov_phone>" & Left(WAB_Get("CellPhone"),16) & "</mov_phone>" & vbCrLf
 sAddress = sAddress & "<fax_phone>" & Left(WAB_Get("BusinessFax"),16) & "</fax_phone>" & vbCrLf
 sAddress = sAddress & "<tx_email>" & Left(WAB_Get("HomeEmail"),100) & "</tx_email>" & vbCrLf
 sAddress = sAddress & "<url_addr>" & WAB_Get("CompanyURL") & "</url_addr>" & vbCrLf
 sAddress = sAddress & "<contact_person>" & Left(WAB_Get("Name"),100) & "</contact_person>" & vbCrLf
 
 WABXML = "<hg_wab>" & vbCrLf
 WABXML = WABXML & "<k_contacts>" & vbCrLf & sContact & "</k_contacts>" & vbCrLf
 WABXML = WABXML & "<k_addresses>" & vbCrLf & sAddress & "</k_addresses>" & vbCrLf
 WABXML = WABXML & "</hg_wab>"
 WAB_XML = WABXML
End Function

Function WAB_URL()
 Dim sContact
 Dim sAddress

 ' Contact Data
 sContact = sContact & "tx_name=" & Escape(Left(WAB_Get("FirstName"),100)) & "&"
 sContact = sContact & "tx_surname=" & Escape(Left(WAB_Get("Surname"),100)) & "&"
 sContact = sContact & "de_title=" & Escape(WAB_Get("Title")) & "&"
 sContact = sContact & "tx_dept=" & Escape(WAB_Get("Department")) & "&"
 sContact = sContact & "tx_location=" & Escape(WAB_Get("Province")) & "&"
 sContact = sContact & "work_phone=" & Escape(Left(WAB_Get("HomePhone"),16)) & "&"
 sContact = sContact & "home_phone=" & Escape(Left(WAB_Get("BusinessPhone"),16)) & "&"
 sContact = sContact & "tx_email=" & Escape(Left(WAB_Get("HomeEmail"),100)) & "&"

 ' Address Data

 sAddress = sAddress & "nm_company=" & Escape(Left(WAB_Get("CompanyName"),70)) & "&"
 sAddress = sAddress & "tx_addr1=" & Escape(Left(WAB_Get("BusinessAddress"),100)) & "&"
 sAddress = sAddress & "nm_country=" & Escape(WAB_Get("Country")) & "&"
 sAddress = sAddress & "nm_state=" & Escape(WAB_Get("Province")) & "&"
 sAddress = sAddress & "nm_city=" & Escape(WAB_Get("City")) & "&"
 sAddress = sAddress & "work_phone=" & Escape(Left(WAB_Get("BusinessPhone"),16)) & "&"
 sAddress = sAddress & "mov_phone=" & Escape(Left(WAB_Get("CellPhone"),16)) & "&"
 sAddress = sAddress & "fax_phone=" & Escape(Left(WAB_Get("BusinessFax"),16)) & "&"
 sAddress = sAddress & "url_addr=" & Escape(WAB_Get("CompanyURL")) & "&"
 sAddress = sAddress & "contact_person=" & Escape(Left(WAB_Get("Name"),100))
 
 WABURL = sContact & sAddress
 
 WAB_URL = WABURL
End Function