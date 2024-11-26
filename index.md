---
---
#### All available Keyple API documentation can be found below

<table>
 <thead>
   <tr>
     <th>Repository</th>
   </tr>
 </thead>
 <tbody>
   {% assign dirs = site.pages | map: 'path' | sort %}
   {% assign seen_dirs = "" | split: "," %}
   {% for dir in dirs %}
     {% assign parts = dir | split: '/' %}
     {% if parts.size > 1 %}
       {% assign subdir = parts[0] %}
       {% unless subdir == "" or subdir == "." or subdir == "assets" or seen_dirs contains subdir %}
         <tr>
           <td><a href="{{ subdir | relative_url }}">{{ subdir }}</a></td>
         </tr>
         {% assign seen_dirs = seen_dirs | push: subdir %}
       {% endunless %}
     {% endif %}
   {% endfor %}
 </tbody>
</table>