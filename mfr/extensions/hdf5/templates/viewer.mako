<script src="/static/js/jquery-1.11.3.min.js"></script>

<link rel="stylesheet" type="text/css" href="/static/css/bootstrap.min.css"/>
<script src="/static/js/bootstrap.min.js"></script>

<div>
    Export URL: ${exported_url}
</div>
<div>
    Tree:
</div>
<div id='h5datasets'>
</div>
<div>
    Preview:
</div>
<div id='h5preview'>
    <div style='height: 200px;'>
        (Select an item in the tree)
    </div>
</div>

## MFR scripts
<script src="/static/js/mfr.js"></script>
<script src="/static/js/mfr.child.js"></script>
<script>
    "use strict";
    // Structure of HDF5 file extracted by render.py
    const datasets = ${datasets};

    // Once the DOM for this document has been loaded, build a tree view
    $(document).ready(function() {
        renderTree($('#h5datasets'), datasets);
    });

    // Rendering a preview
    function renderPreview(fullKey) {
        console.log('Clicked', fullKey);
        const url = '${exported_url}.' + encodeURIComponent(encodeURIComponent(fullKey));
        $.ajax({
            async: true,
            url: url,
            xhrFields: { withCredentials: true },
        }).done(function(data) {
            console.log('Exported', data);
            const dataJSON = JSON.parse(data.toString());
            $('#h5preview').empty().append($('<pre></pre>').css({
                'white-space': 'pre-wrap',
            }).text(JSON.stringify(dataJSON)));
        });
    }

    // Building a tree view    
    function renderTree(container, entities, parentKey) {
        if (entities.length === 0) {
            container.append($('<div>No entities</div>'));
            return;
        }
        const ul = $('<ul></ul>');
        container.append(ul);
        entities.forEach(function(entity) {
            const fullKey = (parentKey || '') + entity.key;
            const li = $('<li></li>');
            const button = $('<button></button>')
                .text(entity.key)
                .click(function() {
                    renderPreview(fullKey);
                });
            li.append(button);
            ul.append(li);

            if (entity.type !== 'Group') {
                return;
            }
            renderTree(li, entity.children || [], fullKey + '/');
        });
    }
</script>
