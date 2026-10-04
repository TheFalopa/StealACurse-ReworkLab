from pathlib import Path
import xml.etree.ElementTree as E
r=Path(__file__).resolve().parents[1]
xml=E.Element('roblox',version='4')
item=E.SubElement(xml,'Item',{'class':'Script','referent':'ToolsLedgerPlugin'})
props=E.SubElement(item,'Properties')
E.SubElement(props,'string',name='Name').text='StealACurseToolsLedger'
E.SubElement(props,'ProtectedString',name='Source').text=(r/'tools/ToolsLedger.plugin.luau').read_text()
E.ElementTree(xml).write(r/'tools/ToolsLedger.plugin.rbxmx',encoding='utf-8',xml_declaration=True)
