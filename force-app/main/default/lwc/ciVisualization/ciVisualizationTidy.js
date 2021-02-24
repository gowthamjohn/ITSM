export const drawTidyTree = function (wholeRecs, param, d3) {
  var self = param;
  self.isRadial = false;
  var data = self.recs,
    svgHeight = 200,
    scale = 1;
  var treeData = {};
  var nodeCount = 0,
    nodeRange = 1000;

  if (wholeRecs == null) {
    treeData.name = data.name;
    treeData.id = data.id;
    treeData.isClicked = true;

    var childrenList = [],
      relationList = [];

    for (var i = 0; i < data.children.length; i++) {
      if (!relationList.includes(data.children[i].relation)) {
        relationList.push(data.children[i].relation);
      }
    }
    var children = [];

    for (var i = 0; i < relationList.length; i++) {
      var relationChildren = {};
      relationChildren.name = relationList[i];
      relationChildren.level = "node";
      relationChildren.children = [];
      var childrenNodes = [];
      for (var j = 0; j < data.children.length; j++) {
        if (data.children[j].relation == relationList[i]) {
          var obj = {};
          obj.name = data.children[j].name + "     ";
          relationChildren.level = "sub node";
          obj.id = data.children[j].id;
          childrenNodes.push(obj);
        }
      }
      nodeCount = nodeCount + childrenNodes.length;
      relationChildren.children = childrenNodes;
      children.push(relationChildren);
    }
    treeData.children = children;
  } else {
    treeData = wholeRecs.data;
    nodeCount = self.nodeCount;
    //  nodeCount = 18;
  }
  self.nodeCount = nodeCount;
  var cutterWidth = 280;
  if (nodeCount > 80) {
    cutterWidth = 180;
  } else if (nodeCount > 50) {
    cutterWidth = 220;
  }
  if (nodeCount >= 200) {
    svgHeight = 70;
    scale = 0.16;
    var cycle = 0,
      count = 30;

    for (var i = 215; i < nodeCount; i++) {
      if (i > 800) {
        count = 80;
      } else if (i > 300) {
        count = 50;
      }
      if (cycle > count) {
        cycle = 0;
        scale = scale - 0.02;
        if (scale < 0.04) {
          scale = 0.055;
        }
      } else {
        cycle++;
      }
    }
  } else if (190 <= nodeCount && nodeCount < 200) {
    svgHeight = 70;
    scale = 0.19;
  } else if (175 <= nodeCount && nodeCount < 190) {
    svgHeight = 70;
    scale = 0.2;
  } else if (170 <= nodeCount && nodeCount < 175) {
    svgHeight = 70;
    scale = 0.22;
  } else if (160 <= nodeCount && nodeCount < 170) {
    svgHeight = 70;
    scale = 0.23;
  } else if (150 <= nodeCount && nodeCount < 160) {
    svgHeight = 70;
    scale = 0.24;
  } else if (140 <= nodeCount && nodeCount < 150) {
    svgHeight = 70;
    scale = 0.25;
  } else if (130 <= nodeCount && nodeCount < 140) {
    svgHeight = 70;
    scale = 0.26;
  } else if (120 <= nodeCount && nodeCount < 130) {
    svgHeight = 70;
    scale = 0.27;
  } else if (110 <= nodeCount && nodeCount < 120) {
    svgHeight = 70;
    scale = 0.3;
  } else if (100 <= nodeCount && nodeCount < 110) {
    svgHeight = 70;
    scale = 0.34;
  } else if (90 <= nodeCount && nodeCount < 100) {
    svgHeight = 70;
    scale = 0.38;
  } else if (nodeCount > 80) {
    svgHeight = 0;
    scale = 0.4;
  } else if (nodeCount > 75) {
    svgHeight = 0;
    scale = 0.43;
  } else if (nodeCount > 70) {
    svgHeight = 0;
    scale = 0.48;
  } else if (nodeCount > 65) {
    svgHeight = 0;
    scale = 0.52;
  } else if (nodeCount > 57) {
    svgHeight = 0;
    scale = 0.55;
  } else if (nodeCount > 50) {
    svgHeight = 0;
    scale = 0.6;
  } else if (nodeCount > 45) {
    svgHeight = 40;
    scale = 0.65;
  } else if (nodeCount > 30) {
    svgHeight = 40;
    scale = 0.7;
  } else if (nodeCount > 20) {
    svgHeight = 40;
    scale = 1;
  } else if (nodeCount > 15) {
    svgHeight = 65;
    scale = 1;
  } else if (nodeCount > 11) {
    svgHeight = 50;
    scale = 1;
  } else {
    svgHeight = 100;
    scale = 1;
  }

  if (nodeCount < 20) {
    nodeRange = 800;
  }
  // Set the dimensions and margins of the diagram
  var margin = { top: 20, right: 90, bottom: 30, left: 90 },
    width = window.innerWidth,
    height = window.outerHeight;
  var focused = false;
  var timeout = null;

  var zoomContainer = d3
    .select(self.template.querySelector(".bodyClass"))
    .append("svg")
    .call(
      d3.zoom().on("zoom", function () {
        zoomContainer.attr("transform", d3.event.transform);
      })
    )
    .on("dblclick.zoom", null)
    .attr("preserveAspectRatio", "xMinYMin meet")
    .attr("width", "85%")
    .attr("height", 590)
    .attr("style", "margin-left: 100px;margin-right: 100px;")
    .append("g");
  var svg = zoomContainer.append("g").attr("transform", function (d) {
    return (
      "translate(" +
      (width / 2 - 283) +
      "," +
      svgHeight +
      ") scale(" +
      scale +
      ")"
    );
  });
  var i = 0,
    duration = 750,
    root;
  // declares a tree layout and assigns the size
  var treemap = d3.tree().size([height, width]);

  // Assigns parent, children, height, depth
  root = d3.hierarchy(treeData, function (d) {
    return d.children;
  });
  root.x0 = height;
  root.y0 = 0;

  // Collapse after the second level
  if (typeof collapse === "undefined") root.children.forEach(collapse);

  update(root);

  // Collapse the node and all it's children
  function collapse(d) {
    if (d.children) {
      d._children = d.children;
      d._children.forEach(collapse);
      d.children = null;
    }
  }

  function update(source) {
    var tooltip = d3
      .select(self.template.querySelector(".bodyClass"))
      .append("div")
      .attr("aura:id", "tooltip")
      .attr("class", "tooltip slds-popover slds-nubbin_right")
      .style("text-align", "center")
      .style("position", "absolute")
      .style("width", "92px")
      .style("height", "53px")
      .style("padding", "3px")
      .style("font", "12px sans-serif")
      .style("background", "rgb(22, 50, 92)")
      .style("border", "0px")
      .style("border-radius", "8px")
      .style("pointer-events", "none")
      .style("color", "white")
      .style("opacity", 0);

    // Assigns the x and y position for the nodes
    var treeData = treemap(root);

    // Compute the new tree layout.
    var nodes = treeData.descendants(),
      links = treeData.descendants().slice(1);
    let left = root;
    let right = root;
    var dx = (nodeCount * 18) / nodeRange;
    // Normalize for fixed-depth.
    nodes.forEach(function (d, index) {
      d.y = d.depth * 180;
      d.x = d.x * ((nodeCount * 20) / nodeRange);
    });

    // ****************** Nodes section ***************************

    // Update the nodes...

    var node = svg.selectAll("g.node").data(nodes, function (d) {
      return d.id || (d.id = ++i);
    });
    // Enter any new modes at the parent's previous position.
    var nodeEnter = node
      .enter()
      .append("g")
      .attr("class", "node")
      .attr("transform", function (d) {
        return "translate(" + source.y0 + "," + source.x0 + ")";
      })
      .on("click", (d) => {
        clearTimeout(timeout);
        timeout = setTimeout(() => {
          self.isLoaded = false;
          if (d.data.level != "sub node") {
            self.template.querySelector(".tooltip").remove();
            d3.select("svg").remove();
            self.tidyTreeUpdate(d, treeData);
            self.isTab = false;
            self.relatedList(d.data.id, self);
            self.nodeName = d.data.name;
          } else {
            self.isTab = false;
          }
        }, 500);
      })
      .on("dblclick", click);

    var activeNodeId = '';
    // Add Circle for the nodes
    nodeEnter
      .append("circle")
      .attr("class", "node")
      .attr("r", 1e-6)
      .on("mouseover", function (d, event) {
        var dataInfo = d;
        var bounds = d3.event.target.getBoundingClientRect();
        activeNodeId = d.id;
        self.getPopOverInfo(d.data.id, function (data) {
          if (!activeNodeId) {
            return;
          }
          tooltip.transition().duration(250).style("opacity", 0.9);
          tooltip
            .html(data.result)
            .style("left", function (d) {
              if (dataInfo.id == 1) {
                self.template
                  .querySelector(".tooltip")
                  .classList.add("slds-nubbin_left");
                self.template
                  .querySelector(".tooltip")
                  .classList.remove("slds-nubbin_right");
                return bounds.left + 10 + "px";
              } else {
                self.template
                  .querySelector(".tooltip")
                  .classList.add("slds-nubbin_right");
                self.template
                  .querySelector(".tooltip")
                  .classList.remove("slds-nubbin_left");
                return bounds.left - 121 + "px";
              }
            })
            .style("top", window.scrollY + bounds.top - 125 + "px");
        });
      })
      .on("mouseout", function (d) {
        tooltip.transition().duration(250).style("opacity", 0);
        activeNodeId = '';
      })
      .style("stroke", function (d) {
        if (d.data.isClicked) {
          return "steelblue";
        } else {
          return "rgb(204, 204, 204)";
        }
      })
      .style("display", function (d) {
        if (d.data.level != "sub node") {
          return "block";
        } else {
          return "none";
        }
      })
      .style("stroke-width", function (d) {
        if (d.data.isClicked) {
          return "6px";
        } else {
          return "5px";
        }
      });

    // Add labels for the nodes
    nodeEnter
      .append("text")
      .attr("dy", ".35em")
      .attr("pointer-events", "none")
      .attr("id", function (d) {
        return d.data.id + "/" + d.data.name;
      })
      .attr("x", function (d) {
        return d.children || d._children ? -13 : 13;
      })
      .attr("text-anchor", function (d) {
        return d.children || d._children ? "end" : "start";
      })
      .text(function (d) {
        return d.data.name + "         ";
      });
    // UPDATE
    var nodeUpdate = nodeEnter.merge(node);

    // Transition to the proper position for the node
    nodeUpdate
      .transition()
      .duration(duration)
      .attr("transform", function (d) {
        return "translate(" + d.y + "," + d.x + ")";
      });

    // Update the node attributes and style
    nodeUpdate
      .select("circle.node")
      .attr("r", 3)
      .style("fill", function (d) {
        if (d.data.isClicked) {
          timeout = setTimeout(function () {
            self.isTab = false;
            self.relatedList(d.data.id, self);
            self.nodeName = d.data.name;
          }, 300);
        }

        return d._children ? "lightsteelblue" : "#fff";
      })
      .attr("cursor", "pointer");

    // Remove any exiting nodes
    var nodeExit = node
      .exit()
      .transition()
      .duration(duration)
      .attr("transform", function (d) {
        return "translate(" + source.y + "," + source.x + ")";
      })
      .remove();

    // On exit reduce the node circles size to 0
    nodeExit.select("circle").attr("r", 1e-6);

    // On exit reduce the opacity of text labels
    nodeExit.select("text").style("fill-opacity", 1e-6);

    // ****************** links section ***************************

    // Update the links...
    var link = svg.selectAll("path.link").data(links, function (d) {
      return d.id;
    });

    // Enter any new links at the parent's previous position.
    var linkEnter = link
      .enter()
      .insert("path", "g")
      .attr("class", "link")
      .style("fill", "none")
      .style("stroke", "#ccc")
      .style("stroke-width", "2px")
      .attr("d", function (d) {
        var o = { x: source.x0, y: source.y0 };
        return diagonal(o, o);
      });

    // UPDATE
    var linkUpdate = linkEnter.merge(link);

    // Transition back to the parent element position
    linkUpdate
      .transition()
      .duration(duration)
      .attr("d", function (d) {
        return diagonal(d, d.parent);
      });

    // Remove any exiting links
    var linkExit = link
      .exit()
      .transition()
      .duration(duration)
      .attr("d", function (d) {
        var o = { x: source.x, y: source.y };
        return diagonal(o, o);
      })
      .remove();

    // Store the old positions for transition.
    nodes.forEach(function (d) {
      d.x0 = d.x;
      d.y0 = d.y;
    });

    // Creates a curved (diagonal) path from parent to the child nodes
    function diagonal(s, d) {
      var path =
        "M" +
        d.y +
        "," +
        d.x +
        "C" +
        (d.y + s.y) / 2 +
        "," +
        d.x +
        " " +
        (d.y + s.y) / 2 +
        "," +
        s.x +
        " " +
        s.y +
        "," +
        s.x;

      return path;
    }

    // Toggle children on click.
    function click(d) {
      clearTimeout(timeout);
      
      d3.event.preventDefault();
      if (d.data.level != "sub node") {
        setTimeout(() => {
          self.isTab = false;
          self.goToButton.bottom = true;
          self.goToButton.top = false;
          self.template.querySelector(".tooltip").remove();
          d3.select("svg").remove();
          self.nodeName = null;
          self.getRecords(d.data.id);
        }, 500);
      }
    }
    function relatedList(d) {
      self.isTab = false;
      self.relatedList(d.data.id, self);
    }
  }
};