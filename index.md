---
---
#### All available Keyple API documentation can be found below

<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.css">

<style>
  .filter-container {
    margin: 20px 0;
    padding: 15px;
    background: #f8f9fa;
    border-radius: 8px;
  }
  .btn-filter {
    margin: 5px;
  }
  .search-box {
    max-width: 400px;
  }
  .table-hover tbody tr {
    cursor: pointer;
  }
  .sortable {
    cursor: pointer;
    user-select: none;
  }
  .sortable:hover {
    background: #e9ecef;
  }
  .sort-icon {
    font-size: 0.8em;
    margin-left: 5px;
  }
  .badge {
    font-size: 0.85em;
  }
  .component-link {
    font-weight: 500;
    color: #0366d6;
    text-decoration: none;
  }
  .component-link:hover {
    text-decoration: underline;
  }
</style>

<div class="filter-container">
  <div class="row g-3 align-items-center">
    <div class="col-auto">
      <label class="form-label mb-0"><strong>Filter by type:</strong></label>
    </div>
    <div class="col-auto">
      <button class="btn btn-sm btn-outline-primary btn-filter" data-filter="all" onclick="filterByType('all')">
        <i class="bi bi-check-all"></i> All
      </button>
      <button class="btn btn-sm btn-outline-success btn-filter" data-filter="java" onclick="filterByType('java')">
        <i class="bi bi-cup-hot"></i> Java
      </button>
      <button class="btn btn-sm btn-outline-danger btn-filter" data-filter="cpp" onclick="filterByType('cpp')">
        <i class="bi bi-code-slash"></i> C++
      </button>
      <button class="btn btn-sm btn-outline-warning btn-filter" data-filter="kmp" onclick="filterByType('kmp')">
        <i class="bi bi-phone"></i> KMP
      </button>
      <button class="btn btn-sm btn-outline-info btn-filter" data-filter="uml" onclick="filterByType('uml')">
        <i class="bi bi-diagram-3"></i> UML
      </button>
    </div>
    <div class="col">
      <input type="text" class="form-control search-box" id="searchBox" placeholder="🔍 Search by name..." onkeyup="filterBySearch()">
    </div>
  </div>
</div>

<table class="table table-hover table-striped" id="repoTable">
  <thead class="table-dark">
    <tr>
      <th class="sortable" onclick="sortTable(0)">Component <span class="sort-icon"><i class="bi bi-arrow-down-up"></i></span></th>
      <th class="sortable" onclick="sortTable(1)">Type <span class="sort-icon"><i class="bi bi-arrow-down-up"></i></span></th>
      <th class="sortable" onclick="sortTable(2)">Category <span class="sort-icon"><i class="bi bi-arrow-down-up"></i></span></th>
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
          {% comment %} Determine type and category {% endcomment %}
          {% assign type = "other" %}
          {% assign type_badge = "secondary" %}
          {% assign category = "unknown" %}

          {% if subdir contains "-java-" %}
            {% assign type = "java" %}
            {% assign type_badge = "success" %}
          {% elsif subdir contains "-cpp-" %}
            {% assign type = "cpp" %}
            {% assign type_badge = "danger" %}
          {% elsif subdir contains "kmp" %}
            {% assign type = "kmp" %}
            {% assign type_badge = "warning" %}
          {% elsif subdir contains "-uml-" %}
            {% assign type = "uml" %}
            {% assign type_badge = "info" %}
          {% endif %}

          {% if subdir contains "-api" %}
            {% assign category = "API" %}
          {% elsif subdir contains "-lib" %}
            {% assign category = "Library" %}
          {% endif %}

          <tr data-type="{{ type }}" data-name="{{ subdir | downcase }}">
            <td>
              <a href="{{ subdir | relative_url }}" class="component-link">{{ subdir }}</a>
            </td>
            <td>
              <span class="badge bg-{{ type_badge }} text-uppercase">{{ type }}</span>
            </td>
            <td>{{ category }}</td>
          </tr>
          {% assign seen_dirs = seen_dirs | push: subdir %}
        {% endunless %}
      {% endif %}
    {% endfor %}
  </tbody>
</table>

<script>
  let currentFilter = 'all';
  let sortDirection = [1, 1, 1]; // 1 for ascending, -1 for descending

  function filterByType(type) {
    currentFilter = type;
    applyFilters();

    // Update button states
    document.querySelectorAll('.btn-filter').forEach(btn => {
      if (btn.getAttribute('data-filter') === type) {
        btn.classList.remove('btn-outline-primary', 'btn-outline-success', 'btn-outline-danger', 'btn-outline-warning', 'btn-outline-info');
        btn.classList.add('btn-primary');
      } else {
        const filterType = btn.getAttribute('data-filter');
        btn.classList.remove('btn-primary');
        if (filterType === 'all') btn.className = 'btn btn-sm btn-outline-primary btn-filter';
        else if (filterType === 'java') btn.className = 'btn btn-sm btn-outline-success btn-filter';
        else if (filterType === 'cpp') btn.className = 'btn btn-sm btn-outline-danger btn-filter';
        else if (filterType === 'kmp') btn.className = 'btn btn-sm btn-outline-warning btn-filter';
        else if (filterType === 'uml') btn.className = 'btn btn-sm btn-outline-info btn-filter';
      }
    });
  }

  function filterBySearch() {
    applyFilters();
  }

  function applyFilters() {
    const searchValue = document.getElementById('searchBox').value.toLowerCase();
    const rows = document.querySelectorAll('#repoTable tbody tr');

    rows.forEach(row => {
      const type = row.getAttribute('data-type');
      const name = row.getAttribute('data-name');

      const matchesType = currentFilter === 'all' || type === currentFilter;
      const matchesSearch = name.includes(searchValue);

      row.style.display = (matchesType && matchesSearch) ? '' : 'none';
    });
  }

  function sortTable(columnIndex) {
    const table = document.getElementById('repoTable');
    const tbody = table.querySelector('tbody');
    const rows = Array.from(tbody.querySelectorAll('tr'));

    sortDirection[columnIndex] *= -1;

    rows.sort((a, b) => {
      const aText = a.cells[columnIndex].textContent.trim().toLowerCase();
      const bText = b.cells[columnIndex].textContent.trim().toLowerCase();

      return sortDirection[columnIndex] * aText.localeCompare(bText);
    });

    rows.forEach(row => tbody.appendChild(row));
    applyFilters(); // Reapply filters after sorting
  }

  // Initialize with 'all' filter active
  document.addEventListener('DOMContentLoaded', function() {
    filterByType('all');
  });
</script>