"use strict";

angular
  .module("obrasMduytApp")
  .directive("statsHome", function ($timeout, $interval, DataService) {
    return {
      restrict: "E",
      scope: {
        obras: "="
      },
      templateUrl: "views/includes/stats-home.html",
      replace: true,
      link: function ($scope, elm, attrs) {
        $scope.i18n = window._i18n;
        $scope.dataUpdatedAt = DataService.getUpdatedAt();

        $scope.total = {
          inversion: 0,
          obras: 0,
          deobras: 0,
          finalizadas: 0,
          enejecucion: 0,
          enproyecto: 0,
          enlicitacion: 0,
          mano_obra: 0,
          porcentaje_finalizadas: 0,
          porcentaje_enejecucion: 0,
          porcentaje_enproyecto: 0,
          porcentaje_enlicitacion: 0
        };

        $scope.totalTemp = angular.copy($scope.total);
        $scope.totalRender = angular.copy($scope.total);

        var obras;
        var chart = {};


        $scope.$watch(attrs.obras, function (value) {
          if (value) {
            obras = angular.copy(value);
            generateTotal();
            setFinalNumbers();
            $scope.dataUpdatedAt = DataService.getUpdatedAt();
          }
        });

        function generateTotal() {
          _.map(obras, function (o) {
            $scope.total.obras += 1;

            if (o.monto_contrato) {
              $scope.total.inversion += o.monto_contrato;
            }

            if (o.mano_obra) {
              $scope.total.mano_obra += o.mano_obra;
            }

            /* 
            if (o.porcentaje_avance == 100) {
              $scope.total.finalizadas += 1;
              $scope.total.porcentaje_finalizadas = Math.round(
                $scope.total.finalizadas * 100 / $scope.total.obras
              );
            }
            */
            if (o.porcentaje_avance == 100) {
              $scope.total.finalizadas += 1;
              $scope.total.porcentaje_finalizadas = $scope.total.finalizadas;
            }
            if (o.porcentaje_avance_enejecucion == 1) {
              $scope.total.enejecucion += 1;
              $scope.total.porcentaje_enejecucion = $scope.total.enejecucion;
            }
            if (o.porcentaje_avance_enproyecto == 2) {
              $scope.total.enproyecto += 1;
              $scope.total.porcentaje_enproyecto = $scope.total.enproyecto;
            }
            if (o.porcentaje_avance_enlicitacion == 3) {
              $scope.total.enlicitacion += 1;
              $scope.total.porcentaje_enlicitacion = $scope.total.enlicitacion;
            }                        
          });
        }

        function setFinalNumbers() {
          $scope.counter_steps = 20;
          $scope.current_step = 0;
          var interval_id = $interval(function () {
            if ($scope.counter_steps == $scope.current_step) {
              $interval.cancel(interval_id);
            } else {
              angular.forEach($scope.total, function (n, dimension) {
                $scope.totalTemp[dimension] =
                  $scope.totalRender[dimension] +
                  $scope.total[dimension] / $scope.counter_steps;
              });
              $scope.totalRender = angular.copy($scope.totalTemp);
            }
            $scope.current_step++;
          }, 200);
        }
      }
    };
  });
