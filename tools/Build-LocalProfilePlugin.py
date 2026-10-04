from pathlib import Path
import xml.etree.ElementTree as ET
root=Path(__file__).resolve().parents[1]
doc=ET.Element('roblox',version='4')
item=ET.SubElement(doc,'Item',{'class':'Script','referent':'LocalProfileStore'})
props=ET.SubElement(item,'Properties')
ET.SubElement(props,'string',name='Name').text='StealACurseLocalProfileStore'
ET.SubElement(props,'ProtectedString',name='Source').text=(root/'tools/LocalProfileStore.plugin.luau').read_text(encoding='utf8')
out=root/'tools/StealACurseLocalProfileStore.rbxmx'
ET.ElementTree(doc).write(out,encoding='utf-8',xml_declaration=True)
print(out)
