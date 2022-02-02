function tool_tip_element()
{
    var element = document.querySelector("#tool-tip");
    if (element === null) {
        element = document.createElement("div");
        element.id = "tool-tip";
        document.querySelector("body").appendChild(element);
    }

    return element;
};

var tool_tip = tool_tip_element();
var html = document.getElementsByTagName("html")[0];

function attach_tool_tip()
{
    document.querySelector("body").onmousemove = function (event)
    {
        var element = event.target;
        if (element.dataset.count === undefined)
            element = event.target.parentNode;

        if (element.dataset.count && element.dataset.count !== "0") {
            tool_tip.textContent = element.dataset.count;
            tool_tip.classList.add("visible");

            if (event.clientY < html.clientHeight - 48)
                tool_tip.style.top = event.clientY + 7 + "px";
            else
                tool_tip.style.top = event.clientY - 32 + "px";

            tool_tip.style.left = event.clientX + 7 + "px";
        }
        else
            tool_tip.classList.remove("visible");
    }
};

attach_tool_tip();

function move_line_to_cursor(cursor_y, line_number)
{
    var id = "L" + line_number;

    var line_anchor =
      document.querySelector("a[id=" + id + "] + span");
    if (line_anchor === null)
        return;

    var line_y = line_anchor.getBoundingClientRect().top + 18;

    var y = window.scrollY;
    window.location = "#" + id;
    window.scrollTo(0, y + line_y - cursor_y);
};

function handle_navbar_clicks()
{
    var line_count = document.querySelectorAll("a[id]").length;
    var navbar = document.querySelector("#navbar");

    if (navbar === null)
        return;

    navbar.onclick = function (event)
    {
        event.preventDefault();

        var line_number =
          Math.floor(event.clientY / navbar.clientHeight * line_count + 1);

        move_line_to_cursor(event.clientY, line_number);
    };
};

handle_navbar_clicks();

function handle_line_number_clicks()
{
    document.querySelector("body").onclick = function (event)
    {
        if (event.target.tagName != "A")
          return;

        var line_number_location = event.target.href.search(/#L[0-9]+\$/);
        if (line_number_location === -1)
          return;

        var anchor = event.target.href.slice(line_number_location);

        event.preventDefault();

        var y = window.scrollY;
        window.location = anchor;
        window.scrollTo(0, y);
    };
};

handle_line_number_clicks();

function handle_collapsible_click()
{
    document.querySelectorAll("summary").forEach(
        function (summary)
        {
            summary.onclick = function (event)
            {
                if (event.shiftKey) {
                    var details = summary.parentElement;
                    var sub_details = details.querySelectorAll("details");
                    var all_are_open = true;
                    sub_details.forEach(
                        function (sub_details) {
                            all_are_open =
                                all_are_open &&
                                sub_details.hasAttribute('open');
                        }
                    );
                    sub_details.forEach(
                        function (details)
                        {
                            if (all_are_open) {
                                details.removeAttribute('open');
                            } else {
                                details.setAttribute('open', '');
                            }
                        }
                    );
                    return false;
                }
            };
        });
}

handle_collapsible_click();
