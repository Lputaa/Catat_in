package com.example.catat_in

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class TrackingWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_tracking_layout)

            val isTracking = widgetData.getBoolean("is_tracking", false)

            if (isTracking) {
                // ── Show tracking state ──
                views.setViewVisibility(R.id.tracking_group, View.VISIBLE)
                views.setViewVisibility(R.id.idle_group, View.GONE)

                val name = widgetData.getString("activity_name", "Aktivitas...") ?: "Aktivitas..."
                val category = widgetData.getString("activity_category", "📌 Lainnya") ?: "📌 Lainnya"
                val startEpochMillis = widgetData.getLong("start_millis", 0L)

                views.setTextViewText(R.id.activity_name, name)
                views.setTextViewText(R.id.activity_category, category)

                // Convert Unix epoch millis → SystemClock.elapsedRealtime base
                val elapsedBase = SystemClock.elapsedRealtime() -
                        (System.currentTimeMillis() - startEpochMillis)
                views.setChronometer(R.id.chronometer, elapsedBase, "%s", true)

                // Tap widget body → open app
                val openPi = HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java,
                    Uri.parse("catatin://open?source=widget")
                )
                views.setOnClickPendingIntent(R.id.widget_root, openPi)
                
                // Stop button → open app to finish tracking
                val stopPi = HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java,
                    Uri.parse("catatin://stop")
                )
                views.setOnClickPendingIntent(R.id.btn_stop, stopPi);

            } else {
                // ── Show idle state ──
                views.setViewVisibility(R.id.tracking_group, View.GONE)
                views.setViewVisibility(R.id.idle_group, View.VISIBLE)

                // Start button → open app tracking form
                val startPi = HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java,
                    Uri.parse("catatin://start")
                )
                views.setOnClickPendingIntent(R.id.btn_start, startPi)

                // Tap idle area → open app
                val openPi = HomeWidgetLaunchIntent.getActivity(
                    context, MainActivity::class.java
                )
                views.setOnClickPendingIntent(R.id.widget_root, openPi)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    companion object {
        fun updateAllWidgets(context: Context) {
            val intent = Intent(context, TrackingWidgetProvider::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            }
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(
                ComponentName(context, TrackingWidgetProvider::class.java)
            )
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            context.sendBroadcast(intent)
        }
    }
}
