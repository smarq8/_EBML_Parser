XA_Save(Array, Path) {
FileDelete, % Path
FileAppend, % "<?xml version=""1.0"" encoding=""UTF-8""?>`n<" . Array . ">`n" . XA_ArrayToXML(Array) . "`n</" . Array . ">", % Path, UTF-8
If (ErrorLevel)
	Return 1
Return 0
}
XA_Load(Path) {
  Local XMLText, XMLObj, XMLRoot, Root1, Root2
  
  If (!FileExist(Path))
	Return 1
	
  FileRead, XMLText, % Path
  
  XMLObj    := XA_LoadXML(XMLText)
  XMLObj    := XMLObj.selectSingleNode("/*")
  XMLRoot   := XMLObj.nodeName
  %XMLRoot% := XA_XMLToArray(XMLObj.childNodes)
  
  Return XMLRoot
}
XA_XMLToArray(nodes, NodeName="") {
   Obj := Object()
	
   for node in nodes
   {
      if (node.nodeName != "#text")  ;NAME
	  {
		If (node.nodeName == "Invalid_Name" && node.getAttribute("ahk") == "True")
		  NodeName := node.getAttribute("id")
		Else
		  NodeName := node.nodeName
	  }
        
      else ;VALUE
		  Obj := node.nodeValue
         
      if node.hasChildNodes
	  {
		;Same node name was used for multiple nodes
		If ((node.nextSibling.nodeName = node.nodeName || node.nodeName = node.previousSibling.nodeName) && node.nodeName != "Invalid_Name" && node.getAttribute("ahk") != "True")
		{
		  ;Create object
		  If (!node.previousSibling.nodeName)
		  {
			Obj[NodeName] := Object()
			ItemCount := 0
		  }
		  
		  ItemCount++
		  
		  ;Use the supplied ID if available
		  If (node.getAttribute("id") != "")
		    Obj[NodeName][node.getAttribute("id")] := XA_XMLToArray(node.childNodes, node.getAttribute("id"))
		
		  ;Use ItemCount if no ID was provided
		  Else
			Obj[NodeName][ItemCount] := XA_XMLToArray(node.childNodes, ItemCount)
	    }
		
		Else
		  Obj.Insert(NodeName, XA_XMLToArray(node.childNodes, NodeName))
	  }
   }
   
   return Obj
}
XA_LoadXML(ByRef data){
   o := ComObjCreate("MSXML2.DOMDocument.6.0")
   o.async := false
   o.LoadXML(data)
   return o
}
XA_ArrayToXML(theArray, tabCount=1, NodeName="") {     
    Local tabSpace, extraTabSpace, tag, val, theXML, root
	tabCount++
    tabSpace := "" 
    extraTabSpace := "" 
	
	if (!IsObject(theArray)) {
	  root := theArray
	  theArray := %theArray%
    }
	
	While (A_Index < tabCount) {
        tabSpace .= "`t" 
		extraTabSpace := tabSpace . "`t"
    } 
     
	for tag, val in theArray {
        If (!IsObject(val))
		{
		  If (XA_InvalidTag(tag))
		    theXML .= "`n" . tabSpace . "<Invalid_Name id=""" . XA_XMLEncode(tag) . """ ahk=""True"">" . XA_XMLEncode(val) . "</Invalid_Name>"
		  Else
			theXML .= "`n" . tabSpace . "<" . tag . ">" . XA_XMLEncode(val) . "</" . tag . ">"
	    }
		
		Else
		{
		  If (XA_InvalidTag(tag))
		    theXML .= "`n" . tabSpace . "<Invalid_Name id=""" . XA_XMLEncode(tag) . """ ahk=""True"">" . "`n" . XA_ArrayToXML(val, tabCount, "") . "`n" . tabSpace . "</Invalid_Name>"
		  Else
		    theXML .= "`n" . tabSpace . "<" . tag . ">" . "`n" . XA_ArrayToXML(val, tabCount, "") . "`n" . tabSpace . "</" . tag . ">"
	    }
    } 
	
	theXML := SubStr(theXML, 2)
	Return theXML
} 
XA_InvalidTag(Tag) {
	Char1      := SubStr(Tag, 1, 1) 
	Chars3     := SubStr(Tag, 1, 3)
	StartChars := "~``!@#$%^&*()_-+={[}]|\:;""'<,>.?/1234567890 	`n`r"
	Chars := """'<>=/ 	`n`r"
	
	Loop, Parse, StartChars
	{
		If (Char1 = A_LoopField)
		  Return 1
	}
	
	Loop, Parse, Chars
	{
		If (InStr(Tag, A_LoopField))
		  Return 1
	}
	
	If (Chars3 = "xml")
	  Return 1
	  
	Return 0
}
XA_XMLEncode(Text) {
StringReplace, Text, Text, &, &, All
StringReplace, Text, Text, <, <, All
StringReplace, Text, Text, >, >, All
StringReplace, Text, Text, ", ", All
StringReplace, Text, Text, ', ', All
Return Text
}