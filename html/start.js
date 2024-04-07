//var statusElement = document.getElementById("status");
//var progressElement = document.getElementById("progress");
//var spinnerElement = document.getElementById("spinner");
var Module = {
    print: function (...t) {
        var n = t.join(" ");
        console.log(n);
    }(),

    canvas: (() => {
        var e = document.getElementById("canvas");
        return e.addEventListener("webglcontextlost", (e => {
            alert("WebGL context lost. You will need to reload the page."), e.preventDefault()
        }), !1), e
    })(),

    setStatus: e => {
        console.log(`Status: ${e}`);
    },
    totalDependencies: 0,

};