
                              < M A T L A B >
                  Copyright 1984-2007 The MathWorks, Inc.
                         Version 7.4.0.287 (R2007a)
                              January 29, 2007

 
  To get started, type one of these: helpwin, helpdesk, or demo.
  For product information, visit www.mathworks.com.
 
>> >> >> >> >> ===============================================
>> example1.json
{
	"data": {
		"firstName": "John",
		"lastName": "Smith",
		"age": 25,
		"address": {
			"streetAddress": "21 2nd Street",
			"city": "New York",
			"state": "NY",
			"postalCode": "10021"
		},
		"phoneNumber": [
			{
				"type": "home",
				"number": "212 555-1234"
			},
			{
				"type": "fax",
				"number": "646 555-4567"
			}
		]
	}
}

{"data": {"firstName": "John","lastName": "Smith","age": 25,"address": {"streetAddress": "21 2nd Street","city": "New York","state": "NY","postalCode": "10021"},"phoneNumber": [{"type": "home","number": "212 555-1234"},{"type": "fax","number": "646 555-4567"}]}}

===============================================
>> example2.json
{
	"data": {
		"glossary": {
			"title": "example glossary",
			"GlossDiv": {
				"title": "S",
				"GlossList": {
					"GlossEntry": {
						"ID": "SGML",
						"SortAs": "SGML",
						"GlossTerm": "Standard Generalized Markup Language",
						"Acronym": "SGML",
						"Abbrev": "ISO 8879:1986",
						"GlossDef": {
							"para": "A meta-markup language, used to create markup languages such as DocBook.",
							"GlossSeeAlso": [
								"GML",
								"XML"
							]
						},
						"GlossSee": "markup"
					}
				}
			}
		}
	}
}

{"data": {"glossary": {"title": "example glossary","GlossDiv": {"title": "S","GlossList": {"GlossEntry": {"ID": "SGML","SortAs": "SGML","GlossTerm": "Standard Generalized Markup Language","Acronym": "SGML","Abbrev": "ISO 8879:1986","GlossDef": {"para": "A meta-markup language, used to create markup languages such as DocBook.","GlossSeeAlso": ["GML","XML"]},"GlossSee": "markup"}}}}}}

===============================================
>> example3.json
{
	"data": {
		"menu": {
			"id": "file",
			"value": "_&File",
			"popup": {
				"menuitem": [
					{
						"value": "_&New",
						"onclick": "CreateNewDoc(\"\"\")"
					},
					{
						"value": "_&Open",
						"onclick": "OpenDoc()"
					},
					{
						"value": "_&Close",
						"onclick": "CloseDoc()"
					}
				]
			}
		}
	}
}

{"data": {"menu": {"id": "file","value": "_&File","popup": {"menuitem": [{"value": "_&New","onclick": "CreateNewDoc(\"\"\")"},{"value": "_&Open","onclick": "OpenDoc()"},{"value": "_&Close","onclick": "CloseDoc()"}]}}}}

===============================================
>> example4.json
{
	"data": [
		{
			"sample": {
				"rho": 1
			}
		},
		{
			"sample": {
				"rho": 2
			}
		},
		[
			[1,0],
			[1,1],
			[1,2]
		],
		[
			"Paper",
			"Scissors",
			"Stone"
		]
	]
}

{"data": [{"sample": {"rho": 1}},{"sample": {"rho": 2}},[[1,0],[1,1],[1,2]],["Paper","Scissors","Stone"]]}

>> >> ===============================================
>> example1.json
{SUdata{SU	firstNameSUJohnSUlastNameSUSmithSUageiSUaddress{SUstreetAddressSU21 2nd StreetSUcitySUNew YorkSUstateSUNYSU
postalCodeSU10021}SUphoneNumber[{SUtypeSUhomeSUnumberSU212 555-1234}{SUtypeSUfaxSUnumberSU646 555-4567}]}}
===============================================
>> example2.json
{SUdata{SUglossary{SUtitleSUexample glossarySUGlossDiv{SUtitleCSSU	GlossList{SU
GlossEntry{SUIDSUSGMLSUSortAsSUSGMLSU	GlossTermSU$Standard Generalized Markup LanguageSUAcronymSUSGMLSUAbbrevSUISO 8879:1986SUGlossDef{SUparaSUHA meta-markup language, used to create markup languages such as DocBook.SUGlossSeeAlso[SUGMLSUXML]}SUGlossSeeSUmarkup}}}}}}
===============================================
>> example3.json
{SUdata{SUmenu{SUidSUfileSUvalueSU_&FileSUpopup{SUmenuitem[{SUvalueSU_&NewSUonclickSUCreateNewDoc(""")}{SUvalueSU_&OpenSUonclickSU	OpenDoc()}{SUvalueSU_&CloseSUonclickSU
CloseDoc()}]}}}}
===============================================
>> example4.json
{SUdata[{SUsample{SUrhoi}}{SUsample{SUrhoi}}[[$i#U
>> 