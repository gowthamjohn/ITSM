export const drawRadialTree = function (wholeRecs, param, d3) {
  var self = param;
  self.isRadial = true;
  var margin = {
      top: 20,
      right: 90,
      bottom: 30,
      left: 90,
    },
    width = "100%",
    height = 1200;
  var timeout = null;
  var tooltip;
  var data = self.recs;
  var topValue = 116;
  var leftValue = 0;
  var treeData = {};
  if (wholeRecs == null) {
    treeData.name = data.name;
    treeData.id = data.id;
    treeData.isClicked = true;
    var childrenLen = data.children.length;
    if (childrenLen >= 41) {
      childrenLen = 40;
    }
    var childrenList = [],
      scope = 0.5;
    for (var i = 0; i < childrenLen; i++) {
      var relObj = {},
        nodeObj = {};
      if (data.children[i].relation) {
        relObj.name = data.children[i].relation;
        relObj.level = "node";
      }
      nodeObj.name = data.children[i].name;
      nodeObj.id = data.children[i].id;
      nodeObj.level = "sub node";
      nodeObj.isClicked = false;
      relObj.children = [];
      relObj.children.push(nodeObj);
      childrenList.push(relObj);
    }
    treeData.children = childrenList;
  } else {
    treeData = wholeRecs.data;
  }

  if (treeData.children.length % 2 != 0) {
    var relObj = {},
      nodeObj = {};
    relObj.name = "";
    relObj.level = "hidden";
    nodeObj.name = "";
    nodeObj.id = "";
    nodeObj.level = "hidden";
    nodeObj.isClicked = false;
    relObj.children = [];
    relObj.children.push(nodeObj);
    treeData.children.push(relObj);
  }

  var textMaxLength = 0,
    radius = 50,
    circleTextLen = 0,
    circleCount = 0,
    svgHeight;
  // Properly formatted treeData, if it's flat data, use stratify

  if (treeData.children.length < 15) {
    circleCount = 1;
    svgHeight = 240;
    scope = 0.4;
    topValue = 112;
    height = 590;
  } else if (treeData.children.length <= 41) {
    circleCount = 2;
    scope = 0.22;
    topValue = 118;
    svgHeight = 250;
    height = 590;
  }

  if (treeData.children) {
    for (var i = 0; i < childrenLen; i++) {
      if (textMaxLength < treeData.children[i].name.length) {
        textMaxLength = treeData.children[i].name.length;
      }
    }

    for (var i = 0; i < childrenLen; i++) {
      if (treeData.children[i].children) {
        for (var j = 0; j < treeData.children[i].children.length; j++) {
          if (circleTextLen < treeData.children[i].children[j].name.length) {
            circleTextLen = treeData.children[i].children[j].name.length;
          }
        }
      }
    }
  } else {
    treeData.children = [];
  }
  var rectPos = {},
    centercircle;
  if (treeData.name.length > 60) {
    centercircle = 100;
  } else if (treeData.name.length > 30) {
    centercircle = 80;
  } else if (treeData.name.length > 20) {
    centercircle = 70;
  } else if (treeData.name.length > 10) {
    centercircle = 60;
  } else {
    centercircle = 50;
  }

  // Prepare container
  var dims = {
    width: 150,
    height: 100,
    svg_dx: 30,
    svg_dy: 30,
  };

  var drag = d3
    .drag()
    .subject(function (d) {
      return d;
    })
    .on("start", dragged)
    .on("drag", dragged)
    .on("end", dragged);
  function dragged() {
    tooltip.transition().style("opacity", 0);
  }
  var zoomContainer = d3
    .select(self.template.querySelector(".bodyClass"))
    .append("svg")
    .call(
      d3.zoom().on("zoom", function () {
        tooltip.transition().style("opacity", 0);
        var transValue = d3.event.transform.k;
        var k = transValue.toFixed(1);
        var temp = 112;
        if (k == 1 || k > 1) {
          for (var i = 1; i < 8; i = i + 0.1) {
            if (scope == 0.4) {
              if (i.toFixed(1) == k) {
                temp = temp - 2;
                break;
              } else {
                temp = temp - 2;
              }
            } else {
              if (i.toFixed(1) == k) {
                if (i < 2.2) {
                  temp = temp;
                } else {
                  temp = temp - 1.25;
                }

                break;
              }
              if (i < 2.2) {
                temp = temp;
              } else {
                temp = temp - 1.25;
              }
            }
          }
        } else if (k < 1) {
          for (var i = 0.9; i > -3; i = i - 0.1) {
            if (i.toFixed(1) == k) {
              temp = temp + 2;
              break;
            }
            temp = temp + 2;
          }
        }

        topValue = temp;
        zoomContainer.attr("transform", d3.event.transform);
      })
    )
    .on("dblclick.zoom", null)
    .attr("width", "85%")
    .attr("height", 590)
    .attr("style", "margin-left: 100px;margin-right: 100px;")
    .append("g");
  var svg = zoomContainer.append("g").attr("transform", function (d) {
  self.d3Track = d3;
    return (
      "translate(" +
      (window.innerWidth / 2 - 100) +
      "," +
      svgHeight +
      ") scale(" +
      scope +
      ")"
    );
  });
  var i = 0,
    cluster_size = 800,
    root;

  // Define cluster

  var cluster = d3.cluster().size([cluster_size, cluster_size]);

  // Get the root

  root = d3.hierarchy(treeData, function (d) {
    return d.children;
  });
  // Collapse all children
  if (typeof collapse === "undefined") root.children.forEach(collapse);

  root.x0 = 0;
  root.y0 = 0;
  // Start drawing
  draw(root, self);

  function draw(source) {
    tooltip = d3
      .select(self.template.querySelector(".bodyClass"))
      .append("div")
      .attr("class", "tooltip  slds-nubbin_left")
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

    var treeData = cluster(root);
    var nodes = treeData.descendants(),
      links = treeData.descendants().slice(1);

    var node = svg.selectAll("g.node").data(nodes, function (d) {
      return d.id || (d.id = ++i);
    });

    // Enter the node, draw it at source, so that we can animate later from
    // source

    var nodeEnter = node
      .enter()
      .append("g")
      .attr("class", "node")
      .attr("aura:id", function (d) {
        return d.data.id;
      })
      .on("click", function (d) {
        clearTimeout(timeout);
        timeout = setTimeout(function () {
          if (d.data.level != "node" && d.data.level != "hidden") {
            self.isLoaded = false;
            if (self.template.querySelector(".tooltip")) {
              self.template.querySelector(".tooltip").remove();
            }
            d3.select("svg").remove(); // Display Related list
            self.treeUpdate(d, treeData, self, d3);
            self.isTab = false;
            self.relatedList(d.data.id, self, self, d3);
            self.nodeName = d.data.name;
          } else {
            self.isTab = false;
          }
        }, 300);
      })

      .on("dblclick", click);

    // Draw a circle with zero radius
    var activeNodeId = '';
    nodeEnter
      .append("circle")
      .attr("class", "node")
      .attr("r", 20)
      .attr("stroke", "steelblue")
      .attr("fill", "white")

      .attr("aura:id", function (d) {
        return d.data.id;
      })
      .attr("stroke-width", "1.5px")
      .attr("display", function (d) {
        if (
          d.data.level == "sub node" ||
          (d.data.level != "node" && d.data.level != "hidden")
        ) {
          return "block";
        } else if (d.data.level == "hidden") {
          return "none";
        } else {
          return "none";
        }
      })
      .on("mouseover", function (d, event) {
        var bounds = d3.event.target.getBoundingClientRect();
        activeNodeId = d.id;
        self.getPopOverInfo(d.data.id, function (data) {
          if (!activeNodeId) {
            return;
          }
          tooltip.transition().duration(500).style("opacity", 0.9);
          tooltip
            .html(data.result)
            .style("left", bounds.right + "px")
            .style("top", window.scrollY + bounds.top - topValue + "px");
        });
      })
      .on("mouseout", function (d) {
        tooltip.transition().duration(500).style("opacity", 0);
        activeNodeId = '';
      });

    nodeEnter
      .append("rect")
      .attr("width", function (d) {
        if (d.data.name.length > 60) {
          return 160;
        } else if (d.data.name.length > 30) {
          return 140;
        } else if (d.data.name.length > 20) {
          return 130;
        } else if (d.data.name.length > 10) {
          return 130;
        } else {
          return 80;
        }
      })
      .attr("height", function (d) {
        if (d.data.name.length > 60) {
          return 150;
        } else if (d.data.name.length > 40) {
          return 120;
        } else if (d.data.name.length > 30) {
          return 90;
        } else if (d.data.name.length > 20) {
          return 80;
        } else if (d.data.name.length > 13) {
          return 50;
        } else {
          return 40;
        }
      })
      .attr("stroke", "steelblue")
      .attr("fill", "white")
      .attr("x", function (d) {
        if (d.data.name.length > 60) {
          return -90;
        } else if (d.data.name.length > 40) {
          return -80;
        } else if (d.data.name.length > 30) {
          return -70;
        } else if (d.data.name.length > 20) {
          return -60;
        } else if (d.data.name.length > 10) {
          return -70;
        } else {
          return -40;
        }
      })
      .attr("y", function (d) {
        if (d.data.name.length > 60) {
          return -60;
        } else if (d.data.name.length > 40) {
          return -60;
        } else if (d.data.name.length > 40) {
          return -55;
        } else if (d.data.name.length > 20) {
          return -45;
        } else if (d.data.name.length > 10) {
          return -25;
        } else {
          return -25;
        }
      })
      .attr("display", function (d) {
        if (d.data.level == "node") {
          return "block";
        } else {
          return "none";
        }
      });

    //Draw text
    nodeEnter
      .append("text")
      //   .class('class','textclass')
      .style("fill", "steelblue")
      .attr("pointer-events", "none")
      .attr("dy", function (d) {
        if (d.data.level == "node") {
          return "0.5em";
        } else {
          return "0.5em";
        }
      })

      .style("text-anchor", "middle")
      .text(function (d, index) {
        if (textMaxLength < d.data.name.length) {
          textMaxLength = d.data.name.length;
        }
        return d.data.name;
      })
      .call(wrap, 100)
      .each(getSize)

      .style("fill", function (d) {
        if (d.data.isClicked) {
          return "white";
        } else {
          return "4188e5";
        }
      })
      .style("font-size", function (d) {
        if (d.data.name.length > 40) {
          return d.scale + 10 + "px";
        } else if (d.data.name.length > 20) {
          return d.scale + 12 + "px";
        } else {
          return d.scale + 14 + "px";
        }
      });

    var nodeUpdate = nodeEnter.merge(node);

    // When we enter the update phase, change the coordinate of each node using a
    // transition, so that we can animate

    nodeUpdate
      .transition()
      .duration(duration)
      .attr("transform", function (d, index) {
        var dist = project(d, d.x, d.y);
        if (d.data.level) {
          dist = project(d, d.x, d.y + 300);
        }

        if (circleCount != 1 && d.data.level != null) {
          if (
            index % 2 == 0 ||
            (index % 2 != 0 && treeData.children.length == index)
          ) {
            dist = project(d, d.x, d.y + 1300);
          } else {
            dist = project(d, d.x, d.y + 500);
          }
        }
        return "translate(" + dist + ")";
      });

    // Add color to circle

    nodeUpdate
      .select("circle.node")
      .attr("r", function (d) {
        if (d.data.name.length > 60) {
          radius = 100;
        } else if (d.data.name.length > 30) {
          radius = 80;
        } else if (d.data.name.length > 20) {
          radius = 70;
        } else if (d.data.name.length > 10) {
          radius = 60;
        } else {
          radius = 50;
        }

        return radius;
      })
      .style("fill", function (d) {
        if (d.data.isClicked) {
          timeout = setTimeout(function () {
            self.isTab = false;
            self.relatedList(d.data.id, self);
            self.nodeName = d.data.name;
          }, 300);
          return "#4188e5";
        } else {
          return "white";
        }
      })
      .attr("cursor", "pointer");

    // Handle exit node, show a transition

    var nodeExit = node
      .exit()
      .transition()
      .duration(duration)
      .attr("transform", function (d) {
        return "translate(" + project(source, source.x, source.y) + ")";
      })
      .remove();

    // On exit reduce the node circles size to 0
    nodeExit.select("circle").attr("r", 1e-6);

    // On exit reduce the opacity of text labels
    nodeExit.select("text").style("fill-opacity", 1e-6);

    var link = svg.selectAll("path.link").data(links, function (d) {
      return d.id || (d.id = i);
    });

    // We need animation for links also, so we first draw paths whose start and origin is

    var linkEnter = link
      .enter()
      .insert("path", "g")
      .attr("class", "link")
      .attr("stroke", "rgb(65, 136, 229)")
      .attr("stroke-width", "1px");

    var linkUpdate = linkEnter.merge(link);

    // Now animate the links

    linkUpdate
      .transition()
      .duration(duration)
      .attr("d", function (d, index) {
        var dist;
        if (d.data.level != "hidden") {
          dist =
            "M" +
            project(d, d.x, d.y + 1200) +
            "L" +
            project(d.parent, d.parent.x, d.parent.y);
          if (d.data.level != null) {
            if (circleCount != 1 && index % 2 == 0) {
              dist =
                "M" +
                project(d, d.x, d.y + 400) +
                "L" +
                project(d.parent, d.parent.x, d.parent.y);
            }
          }

          if (circleCount == 1) {
            dist =
              "M" +
              project(d, d.x, d.y + 300) +
              "L" +
              project(d.parent, d.parent.x, d.parent.y);
          }
        }

        return dist;
      });

    // Remove any exiting links
    var linkExit = link.exit().transition().duration(duration).remove();

    // Store the old positions for transition.
    nodes.forEach(function (d) {
      d.x0 = d.x;
      d.y0 = d.y;
    });
  }

  function project(d, x, y) {
    // Calculate angle, and adjust radius so that links are not too long.
    // Start playing with radius and cluster_size.

    var angle = ((x - cluster_size / 4) / (cluster_size / 2)) * Math.PI,
      radius = y * 0.5;
    var cors = [radius * Math.cos(angle), radius * Math.sin(angle)];
    return cors;
  }

  function collapse(d) {
    if (d.children) {
      d._children = d.children;
      d._children.forEach(collapse);
      d.children = null;
    }
  }

  // We use this function, so that all nodes won't be drawn at same time.
  // Play around with this and check it changes the output
  // If you increase the "value", animation will be slower

  function duration(d) {
    var value = 300 + d.id * 5;
    return value;
  }

  // Toggle children on click.
  function click(d) {
    self.isTab = false;
    self.goToButton.bottom = false;
    self.goToButton.top = false;
    clearTimeout(timeout);

    d3.event.preventDefault();
    if (d.data.level != "node" && d.data.level != "hidden") {
      self.isLoaded = false;
      window.setTimeout(function () {
        if (self.template.querySelector(".tooltip")) {
          self.template.querySelector(".tooltip").remove();
        }
        d3.select("svg").remove();
        self.nodeName = null;
        self.getRecords(d.data.id);
      }, 500);
    }
  }

  function wrap(text, width) {
    //Text embeding in node
    text.each(function () {
      var dy = 0,
        lineHeight = 1.1;
      if (d3.select(this).text().length > 60) {
        dy = -3.5;
      } else if (d3.select(this).text().length > 50) {
        dy = -2.5;
      } else if (d3.select(this).text().length > 40) {
        dy = -1.5;
      } else if (d3.select(this).text().length > 25) {
        dy = -1;
      } else if (d3.select(this).text().length > 15) {
        dy = -0.5;
      }

      var text = d3.select(this),
        words = text.text().split(/\s+/).reverse(),
        word,
        line = [],
        lineNumber = 0,
        //  lineHeight = 1.1, // ems
        x = text.attr("x"),
        y = text.attr("y"),
        tspan = text
          .text(null)
          .append("tspan")
          .attr("x", 0)
          .attr("y", y)
          .attr("dy", dy + "em");
      while ((word = words.pop())) {
        line.push(word);
        tspan.text(line.join(" "));
        if (tspan.node().getComputedTextLength() > width) {
          line.pop();
          tspan.text(line.join(" "));
          line = [word];
          tspan = text
            .append("tspan")
            .attr("x", 0)
            .attr("y", y)
            .attr("dy", lineHeight + 0.2 + "em")
            .text(word);
        }
      }
    });
  }

  function getSize(d) {
    var bbox = this.getBBox(),
      cbbox = this.parentNode.getBBox(),
      scale = Math.min(cbbox.width / bbox.width, cbbox.height / bbox.height);
    d.scale = scale;
  }
};