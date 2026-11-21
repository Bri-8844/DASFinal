// GestiónFTTH - scripts comunes

(function () {
    "use strict";

    // ===== Modal de detalle de la predicción ML.NET =====
    var modal = document.getElementById("modalPrediccion");

    if (modal) {
        modal.addEventListener("show.bs.modal", function (evento) {
            var origen = evento.relatedTarget;
            if (!origen) { return; }

            var d = origen.dataset;
            var disponible = d.disponible === "1";

            function poner(campo, valor) {
                var el = modal.querySelector('[data-campo="' + campo + '"]');
                if (el) { el.textContent = valor; }
            }

            function conUnidad(valor, unidad) {
                return valor ? valor + unidad : "No disponible";
            }

            poner("tarea", d.tarea || "");
            poner("prioridad", d.prioridad || "No disponible");
            poner("duracion", conUnidad(d.duracion, " días"));
            poner("dias", conUnidad(d.dias, " días"));
            poner("avance", conUnidad(d.avance, " %"));
            poner("probabilidad", disponible ? conUnidad(d.probabilidad, " %") : "No disponible");
            poner("mensaje", d.mensaje || "");

            var riesgo = modal.querySelector('[data-campo="riesgo"]');
            if (riesgo) {
                riesgo.textContent = disponible ? d.riesgo : "No disponible";
                riesgo.className = "btn-riesgo " + (d.nivel || "riesgo-nd");
            }

            var demo = modal.querySelector('[data-campo="demo"]');
            if (demo) {
                demo.classList.toggle("d-none", !(disponible && d.demo === "1"));
            }
        });
    }

    // ===== Confirmación de eliminación (formularios con data-confirmar) =====
    document.addEventListener("submit", function (evento) {
        var form = evento.target;
        if (form && form.dataset && form.dataset.confirmar) {
            if (!window.confirm(form.dataset.confirmar)) {
                evento.preventDefault();
            }
        }
    });
})();
