<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(\App\Services\MidtransService::class, function ($app) {
            return new \App\Services\MidtransService();
        });

        $this->app->singleton(\App\Services\ChatbotService::class, function ($app) {
            return new \App\Services\ChatbotService();
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
